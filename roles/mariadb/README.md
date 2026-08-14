# MariaDB

Configures a MariaDB Community Server APT repository on Ubuntu, verifies its
package candidate, installs the server/client packages and manages the service.
Server configuration and database assets remain separate lifecycle stages.

## Scope

- accepts official rolling channels or a pinned `major.minor` release series;
- uses the host's actual Ubuntu suite without cross-release substitution;
- delegates repository and signing-key mechanics to `habr.linuxhost.apt_repo`;
- supports legacy `.list` repositories on focal and Deb822 on jammy and newer;
- refreshes the APT cache after repository changes;
- refuses package installation when the APT candidate does not match the
  selected channel or series;
- installs the server and client without replacing package-owned configuration;
- renders its safe baseline and consumer overrides only into
  `/etc/mysql/mariadb.conf.d/90-ansible.cnf`;
- validates a candidate drop-in with the installed MariaDB option parser before
  notifying the restart handler;
- keeps its built-in server baseline compatible with MariaDB 10.3 and newer.

The role does not run MariaDB's repository setup shell script. It expresses the
same repository state declaratively through the collection's APT helper.

## Variables

- `mariadb_version`: MariaDB repository channel or release series (default:
  `12.rolling`). Set a value such as `12.3` when a consumer needs a series pin.
- `mariadb_repository_name`: repository filename/identifier (default:
  `mariadb`).
- `mariadb_repository_url`: series-specific repository URL.
- `mariadb_repository_suite`: Ubuntu suite; defaults to the gathered release.
- `mariadb_repository_components`: repository components (default: `[main]`).
- `mariadb_repository_arch`: Debian architecture derived from host facts.
- `mariadb_repository_key_url`: direct URL to the repository signing key.
- `mariadb_repository_keyring`: legacy `.list` keyring destination.
- `mariadb_packages`: packages to install (default: `mariadb-server` and
  `mariadb-client`).
- `mariadb_service_name`: service unit name (default: `mariadb`).
- `mariadb_service_enabled`: whether the service is enabled (default: `true`).
- `mariadb_service_state`: desired service state (default: `started`).
- `mariadb_config_manage`: whether to manage the drop-in (default: `true`).
  Setting it to `false` removes the managed file.
- `mariadb_config`: mapping of option-group names to directive mappings
  (default: `{}`). It is recursively combined with the role's safe legacy
  baseline and detected-version overlay, so consumers only need to state
  overrides. Scalar values render once, lists repeat a directive, `null`
  renders a valueless directive, `true` renders `ON`, and `false` omits the
  directive.

## Configuration epochs

The role reads the installed server version and builds the managed file in
this order:

1. the common MariaDB 10.3+ baseline from `vars/main.yml`;
2. one detected-version overlay;
3. consumer overrides from `mariadb_config`.

The current overlays are:

- `config_10_3.yml` for MariaDB 10.3 through 10.5;
- `config_10_6.yml` for MariaDB 10.6 and newer.

The 10.6+ overlay enables `innodb-read-only-compressed=OFF`; the option did not
exist in earlier releases. Both epochs use the shared `[server]` option group
and the same `90-ansible.cnf.j2` renderer. The destination is deliberately
fixed at `/etc/mysql/mariadb.conf.d/90-ansible.cnf`.

## Example

```yaml
mariadb_version: "12.rolling"
mariadb_config:
  server:
    bind-address: "127.0.0.1"
    skip-name-resolve: null
    innodb-buffer-pool-size: "512M"
```

The resulting repository URL is:

```text
https://dlm.mariadb.com/repo/mariadb-server/12.rolling/repo/ubuntu
```

Ubuntu 20.04 focal remains part of the role contract but is deprecated by the
repository vendor. Its availability should remain covered by CI.

## Migrating from the legacy role

Legacy per-option variables are intentionally not retained. Put their MariaDB
directives under the appropriate option group instead:

```yaml
mariadb_config:
  server:
    sql-mode: "STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION"
    character-set-server: utf8mb4
    collation-server: utf8mb4_unicode_ci
    max-allowed-packet: 64M
    innodb-autoinc-lock-mode: 1
```

Repeated directives use lists, which also covers the former replication
template without a special variable model:

```yaml
mariadb_config:
  server:
    server-id: 1
    binlog-ignore-db:
      - information_schema
      - performance_schema
```

The legacy replication and Galera directives are represented with inactive
safe values: binary and relay logs and binlog format are omitted, `log_bin`,
`read_only`, `log_slave_updates` and `wsrep_on` remain off, and no wsrep
provider is loaded.
Consumers that enable a topology must override its complete,
version-appropriate settings and own the associated lifecycle explicitly.

Two version-specific former directives are not part of the shared baseline:
`innodb_thread_concurrency` is absent from current MariaDB, while
`innodb_read_only_compressed` was introduced only in MariaDB 10.6. Consumers
may still supply the latter explicitly when their selected series supports it.
