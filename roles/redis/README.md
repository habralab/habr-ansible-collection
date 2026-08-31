# Redis

Installs Redis on Ubuntu Focal and newer while retaining the configuration
shipped by the selected package version. The role manages a Redis server and an
optional Sentinel discovery endpoint independently, so a host can run either or
both components.

## Configuration model

The role does not edit or replace `/etc/redis/redis.conf`. It starts the
packaged service with `/etc/redis/redis-ansible.conf`, which includes the stock
file first and `/etc/redis/redis.conf.d/*.conf` last. Ansible owns only
`90-ansible.conf` and the small systemd drop-in selecting the wrapper.

This makes package defaults transitive across Redis versions: upgrades replace
or merge their own stock conffile as usual, while explicit role overrides keep
winning because they are read last.

`redis_server_config` is a mapping from an exact Redis directive to a value.
Booleans render as `yes`/`no`, `null` renders a valueless directive, and a list
renders the directive once per item. Other values are emitted verbatim; quote
values in YAML when Redis syntax requires quoting.

Configuration task output is hidden by default because this mapping may contain
passwords. Secrets should still be stored in Ansible Vault.

## Repositories

`redis_repository` accepts:

- `ubuntu` (default): use the distribution archive without adding a source;
- `official`: add the current official `packages.redis.io` repository through
  `habr.linuxhost.apt_repo`; it supports Ubuntu Jammy, Noble and Resolute;
- `ppa_redislabs`: add the historical Redis Labs PPA through
  `habr.linuxhost.apt_repo`; it currently publishes for Focal, Jammy and Noble;
- `unmanaged`: use a repository configured outside this role.

The PPA itself recommends the newer official Redis APT repository and currently
stops at Redis 7.4. It remains available for the Focal-era compatibility
contract, but is not the default.

## Variables

```yaml
redis_repository: ubuntu
redis_repository_manage: true
redis_package_version: ""

redis_server_packages:
  - redis-server
redis_server_enabled: true
redis_server_package_state: present
redis_server_service_enabled: true
redis_server_service_state: started

redis_server_config_manage: true
redis_server_config_no_log: true
redis_server_config: {}

redis_sysctl: {}

redis_sentinel_enabled: false
redis_sentinel_bind: 127.0.0.1 -::1
redis_sentinel_port: 26379
redis_sentinel_protected_mode: true
redis_sentinel_requirepass: ""
redis_sentinel_monitors: []
redis_sentinel_reseed: false
```

`redis_package_version` accepts the complete Debian version reported by
`apt policy`. When non-empty, that exact version is requested for every enabled
server and Sentinel package and APT downgrades are allowed so the declared
version remains convergent. Package names must not already contain `=version`.

For example, Redis 8.2.8 from the official repository on Ubuntu Noble is:

```yaml
redis_repository: official
redis_package_version: "6:8.2.8-1rl1~noble1"
redis_server_packages:
  - redis-server
```

The complete Debian version is distribution-specific. Obtain it from the
configured repository instead of constructing it from the upstream version.

Example overrides:

```yaml
redis_server_config:
  bind: 127.0.0.1 10.0.0.10
  protected-mode: true
  maxmemory: 512mb
  maxmemory-policy: allkeys-lru
  save:
    - 900 1
    - 300 10
```

`redis_sysctl` is an optional mapping for Redis-specific kernel requirements,
for example `vm.overcommit_memory: "1"` on hosts that use background saves.

## Tags

- `redis_repository`
- `redis_packages`
- `redis_config`
- `redis_sentinel`

## Sentinel discovery

The stock Ubuntu `sentinel.conf` contains an active example monitor, while a
running Sentinel rewrites its configuration with IDs, epochs and observed
topology. The role therefore never uses that stock example and never templates a
complete file on every run. It seeds `/etc/redis/sentinel-ansible.conf` only
when absent, gives it to the `redis` user, and starts the packaged service with
that writable state file through a systemd drop-in.

Every declared monitor is checked after startup with
`SENTINEL GET-MASTER-ADDR-BY-NAME`. Both the Sentinel client password and each
monitor's `auth_pass` should come from Ansible Vault; Sentinel task output is
hidden by default.

```yaml
redis_server_enabled: false
redis_sentinel_enabled: true
redis_sentinel_bind: "0.0.0.0 ::"
redis_sentinel_requirepass: "{{ vault_redis_sentinel_requirepass }}"
redis_sentinel_monitors:
  - name: amassica-staging
    host: 10.114.0.2
    port: 6379
    quorum: 1
    auth_pass: "{{ vault_redis_requirepass }}"
```

Monitor variables are bootstrap inputs rather than a whole-file desired state.
Changing them after the seed exists intentionally fails the discovery check
instead of erasing Sentinel runtime state. API-based monitor reconciliation and
credential rotation are separate future capabilities.

Setting `redis_sentinel_reseed: true` explicitly stops Sentinel and removes its
writable state before recreating it from the bootstrap variables. This is a
destructive recovery/rotation operation and must not be stored as a persistent
host default.

## Upstream documentation

- https://redis.io/docs/latest/operate/oss_and_stack/install/install-stack/apt/
- https://github.com/redis/redis-debian
