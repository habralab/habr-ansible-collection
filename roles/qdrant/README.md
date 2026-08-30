# Qdrant

Installs Qdrant from a pinned official Debian package and manages a standalone
systemd service on Ubuntu.

## Scope

- Download and install an official `.deb` with SHA-256 verification.
- Create a dedicated system user and group.
- Prepare persistent storage and snapshot directories.
- Manage a systemd service through `habr.linuxhost.systemd_unit`.
- Optionally deploy a YAML configuration overlay.
- Verify the local readiness endpoint after startup.

## Package

Qdrant `1.19.0-1` for `amd64` is pinned by default. The package URL and checksum
can be overridden together for another release:

```yaml
qdrant_version: "1.20.0"
qdrant_package_revision: "1"
qdrant_package_url: >-
  https://example.org/releases/qdrant_1.20.0-1_amd64.deb
qdrant_package_checksum: "sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
```

The role does not install floating or latest releases.

## Configuration Ownership

`qdrant_config_manage` defaults to `false`. Package installation and service
lifecycle therefore leave the package-owned `/etc/qdrant/config.yaml`
untouched.

When configuration ownership is explicitly enabled, the role writes only
`/etc/qdrant/90-ansible.yaml` and starts Qdrant with that file as an additional
configuration source. The package configuration remains in place.

```yaml
qdrant_config_manage: true
qdrant_config_overrides:
  service:
    host: 127.0.0.1
    http_port: 6333
    grpc_port: 6334
```

If the configured HTTP listener is not reachable through
`127.0.0.1:6333`, set the readiness target explicitly:

```yaml
qdrant_health_host: 192.0.2.10
qdrant_health_port: 6333
```

Configuration task output is hidden by default because the mapping may contain
API keys. Store sensitive values in Ansible Vault or another secret store.

## Service And Paths

```yaml
qdrant_user: qdrant
qdrant_group: qdrant

qdrant_var_dir: /var/lib/qdrant
qdrant_storage_dir: /var/lib/qdrant/storage
qdrant_snapshots_dir: /var/lib/qdrant/snapshots

qdrant_service_enabled: true
qdrant_service_state: started
qdrant_service_restart: always
```

Standard output and error use the systemd journal. The role does not configure
network firewall rules; restrict Qdrant listeners with the host firewall or a
separate network policy.

## Check Mode

On a fresh host, check mode validates the complete contract and reports the
pending package installation without assuming that the package-created files
already exist. Managed configuration and readiness checks are evaluated after
the Qdrant binary is present.

## Tags

- `qdrant`
- `qdrant_packages`
- `qdrant_config`
- `qdrant_service`

## Non-goals

- Collection creation or migration.
- Cluster bootstrap or membership management.
- Backup and restore workflows.
- TLS certificate provisioning.
- Firewall management.
- In-place major-version upgrades.

## Upstream Documentation

- https://qdrant.tech/documentation/guides/installation/
- https://qdrant.tech/documentation/guides/configuration/
