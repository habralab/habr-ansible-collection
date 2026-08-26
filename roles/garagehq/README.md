# Garage HQ Ansible Role

This role installs and configures
[Garage](https://garagehq.deuxfleurs.fr/), a distributed, S3-compatible object
storage system.

The role provides a **secure, idempotent baseline setup** suitable for
single-node deployments and early multi-node clusters.
Cluster lifecycle management is intentionally out of scope.

Official documentation:
https://garagehq.deuxfleurs.fr/documentation/

---

## What this role does

- Downloads and installs the Garage binary
- Creates a dedicated system user and group
- Installs and manages a systemd service
- Generates and manages `garage.toml`
- Handles the RPC secret securely using `rpc_secret_file`
- Configures the following Garage APIs:
  - RPC
  - S3 API
  - S3 Web API
  - K2V API
  - Admin API (optional tokens, metrics, tracing)

---

## Upstream configuration reference

This role maps Ansible variables to the official Garage configuration format.

Authoritative reference:
https://garagehq.deuxfleurs.fr/documentation/reference-manual/configuration/

The sections below describe **how this role implements** specific parts of that
configuration and highlight non-obvious behavior.

---

## RPC configuration and secret handling

Upstream documentation:
- https://garagehq.deuxfleurs.fr/documentation/reference-manual/configuration/#rpc_secret
- https://garagehq.deuxfleurs.fr/documentation/reference-manual/configuration/#rpc_public_addr
- https://garagehq.deuxfleurs.fr/documentation/reference-manual/configuration/#bootstrap_peers

### RPC secret behavior

This role uses a file-based approach (`rpc_secret_file`), as recommended by
upstream documentation.

Behavior:
- Secrets are **never embedded** directly into `garage.toml`
- If `garagehq_conf_rpc_secret` is provided, it is written once to the secret file
- If no secret is provided and the file does not exist, a random secret is
  generated (`openssl rand -hex 32`)
- Existing secret files are preserved unless explicitly forced
- File permissions are enforced to satisfy Garage security checks (`0600`)

Relevant variables:
- `garagehq_conf_rpc_secret`
- `garagehq_conf_rpc_secret_file`
- `garagehq_conf_rpc_secret_force`

---

## API configuration

### S3 API

Upstream documentation:
- https://garagehq.deuxfleurs.fr/documentation/reference-manual/configuration/#s3_api

This role configures:
- bind address
- root domain
- region name

---

### S3 Web API

Upstream documentation:
- https://garagehq.deuxfleurs.fr/documentation/reference-manual/configuration/#s3_web

This role configures:
- bind address
- root domain
- index file

---

### K2V API

Upstream documentation:
- https://garagehq.deuxfleurs.fr/documentation/reference-manual/configuration/#k2v_api

This role configures the K2V API bind address only.

---

## Admin API and metrics

Upstream documentation:
- https://garagehq.deuxfleurs.fr/documentation/reference-manual/configuration/#admin

The Admin API is enabled via `api_bind_addr`.

Admin and metrics tokens are **optional** and **never auto-generated** by this
role. If variables are unset, the corresponding configuration lines are omitted.

Supported options:
- Admin API bind address
- Admin token
- Metrics token
- Metrics token enforcement
- OpenTelemetry trace sink

This design avoids implicit secrets and allows integration with external
secret management systems.

---

## Runtime model and systemd integration

- Garage runs as a dedicated, non-login system user
- A systemd unit is installed and enabled by default
- Runtime configuration is provided via an environment file:
  `/etc/default/garage`

The service is started as:

```
garage -c $GARAGE_CONFIG server
```

Basic sanity checks are performed before startup
(binary and configuration file presence).

---

## Configuration variables

This role exposes configuration via variables prefixed with `garagehq_`.

Garage `2.3.0` is installed by default. Set `garagehq_version` to pin another
release and `garagehq_arch` to select an upstream binary target.

The **complete and authoritative list** of available variables, defaults and
inline documentation can be found in:

```
roles/garagehq/defaults/main.yml
```


Only key behaviors and non-obvious options are documented in this README.

---

## Limitations and non-goals

This role does **not** implement:

- Garage cluster lifecycle management
- Node join / leave automation
- TLS or certificate management
- Reverse proxy configuration
- User, access key or bucket management
- Metrics scraping or exporters

These concerns are expected to be handled by separate roles or operational
tooling.

---

## Requirements

- ansible-core >= 2.16
- Supported platforms: Ubuntu (focal, jammy, noble)

---

## Example usage

```yaml
- name: Install Garage HQ
  hosts: garage_nodes
  become: true
  roles:
    - habr.linuxhost.garagehq
```
