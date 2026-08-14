# MariaDB assets

Manages application databases and accounts on an existing MariaDB server.
The role connects as a local administrative user through the Unix socket,
creates databases before accounts and does not change root authentication,
anonymous accounts or server configuration.

## Requirements

The target MariaDB server must already be installed and running. The parent
collection declares its `ansible.mariadb` dependency; the role installs the
target-side PyMySQL package.

## Variables

- `mariadb_assets_python_packages`: target packages providing PyMySQL
  (default: `[python3-pymysql]`).
- `mariadb_assets_login_unix_socket`: local administrative socket (default:
  `/run/mysqld/mysqld.sock`).
- `mariadb_assets_login_user`: local administrative account (default: `root`).
- `mariadb_assets_databases`: database contracts. Each entry requires `name`
  and `state`; a present database also requires `encoding` and `collation`.
- `mariadb_assets_users`: account contracts. Each entry requires `name`,
  `host` and `state`; a present account also requires `password` and `priv`.
  `update_password` accepts `always`, `on_create` or `on_new_username` and
  defaults to `always`.

Passwords should come from Ansible Vault or another deployment secret store.
Account tasks suppress their complete result because module output may contain
credentials.

## Example

```yaml
mariadb_assets_databases:
  - name: example
    state: present
    encoding: utf8mb4
    collation: utf8mb4_unicode_ci

mariadb_assets_users:
  - name: example
    host: 127.0.0.1
    state: present
    password: "{{ vault_example_database_password }}"
    priv: "example.*:ALL"
    update_password: always
```

The role deliberately does not import or dump data. Those operations require a
separate lifecycle contract because the database module cannot make imports
idempotent.
