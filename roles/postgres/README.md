# PostgreSQL

Installs one supported PostgreSQL major version from the official PostgreSQL
Global Development Group APT repository and manages its standalone service on
Ubuntu.

## Scope

- Configure PGDG through `habr.linuxhost.apt_repo`.
- Install versioned server and client packages.
- Manage the package-provided `postgresql` service.
- Optionally add a server configuration fragment.
- Optionally add explicit client authentication rules.
- Verify readiness with `pg_isready`.

Database roles, databases and extensions belong to
`habr.linuxhost.postgres_assets` and are not managed here.

## Package and repository

PostgreSQL 18 is selected by default:

```yaml
postgres_version: "18"
postgres_repository_manage: true
```

The managed PGDG repository is supported on Ubuntu Jammy, Noble and Resolute.
Set `postgres_repository_manage: false` when an operator or another role owns
the package source. Package names remain configurable through
`postgres_packages`.

The role selects a major package series rather than an exact minor package
revision so normal PostgreSQL security and bug-fix updates remain available.

## Configuration ownership

Both configuration models are disabled by default:

```yaml
postgres_config_manage: false
postgres_config: {}

postgres_hba_manage: false
postgres_hba_rules: []
```

With these defaults the role does not create, remove or edit PostgreSQL
configuration. Package installation and service lifecycle remain independent.

When enabled with a non-empty mapping, `postgres_config` is rendered to the
Debian/PGDG `conf.d` include directory. The package-owned `postgresql.conf`
remains untouched. Boolean values render as `on` and `off`; other scalar values
are emitted verbatim, including any PostgreSQL quoting:

```yaml
postgres_config_manage: true
postgres_config:
  listen_addresses: "'127.0.0.1'"
  port: 5432
  max_connections: 100
```

HBA management requires PostgreSQL 16 or newer because it uses the upstream
`include_dir` directive. The role appends one include directive to the stock
`pg_hba.conf` and owns only its `90-ansible.conf` fragment:

```yaml
postgres_hba_manage: true
postgres_hba_rules:
  - type: host
    database: example
    user: example
    address: 192.0.2.10/32
    method: scram-sha-256
```

HBA records are evaluated in order. The fragment is included after the stock
rules, so consumers must review the effective rule order for their package and
security policy.

## Service and readiness

```yaml
postgres_cluster_name: main
postgres_service_enabled: true
postgres_service_state: started

postgres_health_check_enabled: true
postgres_health_host: 127.0.0.1
postgres_health_port: 5432
```

Configuration changes restart PostgreSQL because not every server setting can
be applied by reload. Set the readiness endpoint to an address actually used by
the configured listener.

## Tags

- `postgres`
- `postgres_repository`
- `postgres_packages`
- `postgres_config`
- `postgres_hba`
- `postgres_service`

## Non-goals

- Database, role, extension or privilege management.
- Replication, clustering or automatic failover.
- Backup, restore or major-version migration.
- PgBouncer installation or configuration.
- Firewall management.
- Exact minor-version pinning.

## References

- https://www.postgresql.org/download/linux/ubuntu/
- https://www.postgresql.org/docs/current/config-setting.html
- https://www.postgresql.org/docs/current/auth-pg-hba-conf.html
