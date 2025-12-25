# Roles index

This document provides a high-level overview of roles included in the **habr.linuxhost** Ansible collection.

For detailed documentation, configuration options and examples, refer to the `README.md` file located inside each role directory.

---

## Available roles

### `garagehq`

Installs and configures
[Garage](https://garagehq.deuxfleurs.fr/), a distributed, S3-compatible object
storage system.

Scope:
- Binary installation
- systemd service management
- Secure configuration file generation
- RPC secret handling via `rpc_secret_file`
- Configuration of S3, S3 Web, K2V and Admin APIs

Non-goals:
- Cluster lifecycle management
- TLS and reverse proxy setup
- User, access key or bucket management

Documentation:
- `roles/garagehq/README.md`
- Upstream reference:
  https://garagehq.deuxfleurs.fr/documentation/

---

## Role design principles

All roles in this collection follow these principles:

- Idempotent and safe defaults
- Explicit handling of secrets (no implicit generation unless required)
- Minimal scope with clear non-goals
- Upstream documentation is referenced, not duplicated
- One role — one responsibility

---

## Adding new roles

When adding a new role to this collection:

1. Place the role under `roles/<role_name>/`
2. Provide a `README.md` inside the role directory
3. Document only key behaviors and non-obvious options
4. Reference upstream documentation where applicable
5. Add the role to this index

---

## Versioning

Roles are versioned as part of the collection. Refer to the collection `CHANGELOG.md` for released versions and changes.
