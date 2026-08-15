# MongoDB

Installs and configures MongoDB Community Server from the official MongoDB APT
repository on Ubuntu. The role manages one `mongod` service and can explicitly
take ownership of a declarative YAML configuration, keyfile authorization, and
bootstrap of a single-member replica set.

## Compatibility

The role distinguishes MongoDB's published platform support from APT repository
availability. `mongodb_platform_policy: upstream` is the default and accepts
only combinations in the upstream support matrix. `repository` additionally
accepts suites for which MongoDB publishes signed packages but has not yet
listed the OS in its platform matrix.

MongoDB 8.2 and 8.3 repositories continue to use the MongoDB 8.0 release
signing key; the role maps repository versions to signing-key versions rather
than deriving a nonexistent key URL.

| MongoDB | Focal | Jammy | Noble | Resolute |
|---------|-------|-------|-------|----------|
| 7.0 | upstream | upstream | - | - |
| 8.0 | upstream | upstream | upstream | - |
| 8.2 | upstream | upstream | upstream | - |
| 8.3 | upstream | upstream | upstream | explicit Noble fallback |

MongoDB 6.0 and older are excluded because they are end-of-life. MongoDB's
Resolute APT indexes currently contain database tools but no server packages.
The tested Resolute path therefore uses signed Noble 8.3 packages and requires
explicit repository and kernel-compatibility choices described below.

MongoDB 8.x must not use TCMalloc per-CPU caches on Linux kernels from 6.19
through 7.0.13 due to an upstream RSEQ incompatibility. The role fails before
repository or package changes unless the explicit lower-performance fallback
is enabled for MongoDB 8.2 or newer.

Upstream references:

- https://www.mongodb.com/docs/community-platform-support/
- https://www.mongodb.com/docs/manual/administration/production-notes/
- https://www.mongodb.com/docs/manual/tutorial/install-mongodb-on-ubuntu/

## Basic Server

```yaml
mongodb_version: "8.0"
mongodb_packages:
  - mongodb-org

mongodb_service_enabled: true
mongodb_service_state: started

mongodb_config_manage: true
mongodb_storage_db_path: /var/lib/mongodb
mongodb_system_log_path: /var/log/mongodb/mongod.log
mongodb_net_port: 27017
mongodb_net_bind_ip: 127.0.0.1
```

`mongodb_config_manage` defaults to `false`. Package installation and service
lifecycle therefore leave the package-owned `/etc/mongod.conf` untouched until
the operator explicitly transfers configuration ownership to the role.
Replica-set and authorization settings require managed configuration and fail
validation otherwise.

`mongodb_config_overrides` recursively overlays the role baseline before
role-owned replication and security fields are added:

```yaml
mongodb_config_overrides:
  storage:
    wiredTiger:
      engineConfig:
        cacheSizeGB: 1
  setParameter:
    diagnosticDataCollectionEnabled: false
```

## Resolute

MongoDB does not currently publish `mongodb-org-server` in its Resolute APT
indexes. MongoDB 8.3.8 Noble packages have been exercised on Resolute amd64,
but this remains outside MongoDB's platform matrix. The affected Resolute
kernel also requires keeping glibc's RSEQ registration enabled, which makes
TCMalloc fall back from per-CPU to per-thread caches and can reduce performance.

Enabling both deliberate compatibility boundaries requires:

```yaml
mongodb_version: "8.3"
mongodb_platform_policy: repository
mongodb_repository_suite: noble
mongodb_tcmalloc_rseq_workaround: true
```

The role delegates a systemd drop-in with
`GLIBC_TUNABLES=glibc.pthread.rseq=1`. Remove the workaround after booting a
kernel with the complete RSEQ fix and after MongoDB supports the distro's
kernel version mapping. Cross-release suite substitution is never a default.
The variable is tri-state: `null` leaves the drop-in unmanaged, `true` ensures
it is present, and `false` explicitly removes this role's drop-in.

## Replica Set And Authorization

The initial topology contract bootstraps exactly one member. Use a DNS hostname
for its replica-set identity; MongoDB 5.0 and newer reject IP-only member
configurations in common split-horizon cases.

```yaml
mongodb_replica_set_name: amassica-staging
mongodb_replica_set_initiate: true
mongodb_replica_set_member: localhost:27017

mongodb_config_manage: true
mongodb_security_authorization: true
mongodb_security_keyfile_state: present
mongodb_security_keyfile_content: "{{ vault_mongodb_keyfile }}"
mongodb_admin_user: ansible-admin
mongodb_admin_password: "{{ vault_mongodb_admin_password }}"
mongodb_admin_roles:
  - role: root
    db: admin
```

On a new deployment, the role starts `mongod` with keyfile access control,
initiates the replica set through MongoDB's localhost exception, waits for a
primary, and creates the first administrator. Subsequent runs authenticate and
verify health without recreating or rotating the administrator.

The keyfile must contain 6-1024 base64 characters. It is written as
`mongodb:mongodb` with mode `0400`. Store both keyfile and password values in
Ansible Vault. `mongodb_security_keyfile_state` defaults to `unmanaged`; use
`absent` only for deliberate cleanup of the configured keyfile path.

## Check Mode

On an unprepared host, check mode validates the platform and reports package
changes without assuming that the package-created `mongodb` account or binaries
already exist. Replica-set initiation and first-user creation run only in normal
mode. On a prepared host, configuration and service state are checked normally.

## Tags

- `mongodb`
- `mongodb_repository`
- `mongodb_packages`
- `mongodb_config`
- `mongodb_security`
- `mongodb_replica_set`

## Migration From The Legacy Role

- `mongodb_server` is removed; this role always provisions a server.
- `mongodb_tools` and the unconditional shell/tools installation are removed;
  select packages through `mongodb_packages`.
- `mongodb_conf_*` variables map to the shorter server/config variables above.
- `mongodb_conf_replication_repl_set_name` becomes
  `mongodb_replica_set_name`.
- The unversioned exporter binary from Habr storage is intentionally not
  migrated. Exporter lifecycle belongs in a separately versioned role.

## Non-goals

- Multi-member replica-set orchestration or reconfiguration.
- Sharding.
- Application database/user lifecycle beyond the first administrator.
- Exporter installation.
- In-place major-version upgrades.
