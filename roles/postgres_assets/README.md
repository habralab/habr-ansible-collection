# PostgreSQL assets

Manages application login roles, databases and database extensions on an
existing PostgreSQL server. Server installation, PostgreSQL configuration and
network policy remain separate lifecycle stages.

## Requirements

- An already-running PostgreSQL server.
- `community.postgresql >=4.0.0,<5.0.0`, declared by this collection.
- Psycopg in the target Ansible Python environment.

The default local connection uses the `postgres` operating-system account and
Unix-socket peer authentication. Connection and privilege-escalation variables
can be overridden for another administrative model.

## No-op defaults

```yaml
postgres_assets_roles: []
postgres_assets_databases: []
```

When both lists are empty, the role validates its public contract and performs
no package installation, connection or database mutation.

## Connection

```yaml
postgres_assets_login_host: ""
postgres_assets_login_port: 5432
postgres_assets_login_user: postgres
postgres_assets_login_password: ""
postgres_assets_login_database: postgres
postgres_assets_login_unix_socket: /var/run/postgresql
postgres_assets_ssl_mode: prefer

postgres_assets_become: true
postgres_assets_become_user: postgres
```

Credentials must come from Ansible Vault or another secret store. Module task
output is hidden by default through `postgres_assets_no_log: true`.

## Roles

Present roles require a password. The role passes plaintext or pre-hashed values
to PostgreSQL with encrypted storage enabled. `role_attr_flags` defaults to
`LOGIN`.

```yaml
postgres_assets_roles:
  - name: example
    state: present
    password: "{{ vault_example_postgres_password }}"
    role_attr_flags: LOGIN
```

Optional role fields are `comment`, `expires`, `conn_limit`, `configuration`,
`reset_unspecified_configuration`, and `no_password_changes`. An absent role
accepts only `name` and `state`.

Present roles are reconciled before databases. Absent roles are removed after
database and extension processing so a database can be removed before its
owner.

## Databases and extensions

Present databases require an explicit owner. Encoding, locale, template,
comment and connection limit remain optional and retain module/package defaults
when omitted.

```yaml
postgres_assets_databases:
  - name: example
    state: present
    owner: example
    encoding: UTF8
    extensions:
      - name: pg_trgm
        state: present
```

Extension entries also accept `schema`, `version`, and `cascade`. The role does
not install operating-system packages that provide third-party extensions.

To remove a database explicitly:

```yaml
postgres_assets_databases:
  - name: retired_example
    state: absent
    force: true
```

## Check mode

On a prepared target, the PostgreSQL modules support check mode. On a first
check-mode run, package installation is predicted but assets cannot be inspected
until Psycopg is actually installed; the role reports this boundary and skips
database mutations.

## Tags

- `postgres_assets`
- `postgres_assets_packages`
- `postgres_assets_roles`
- `postgres_assets_databases`
- `postgres_assets_extensions`

## Non-goals

- Installing or configuring PostgreSQL server packages.
- HBA or firewall management.
- Arbitrary object grants, schemas, tables or migrations.
- Dump, restore or seed lifecycle.
- Removing assets omitted from the declared lists.

## References

- https://docs.ansible.com/ansible/latest/collections/community/postgresql/postgresql_user_module.html
- https://docs.ansible.com/ansible/latest/collections/community/postgresql/postgresql_db_module.html
- https://docs.ansible.com/ansible/latest/collections/community/postgresql/postgresql_ext_module.html
