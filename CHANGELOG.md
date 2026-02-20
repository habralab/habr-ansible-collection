# Changelog

## [1.2.0] - 2026-02-20

### Added
- Production-ready role: `users`:
  - Declarative management of system and normal Linux users via a unified list.
  - Configuration of UID, shell, home directories, and group memberships.
  - Safe, idempotent password hash assignment.
- Production-ready role: `nvm`:
  - Git-based Node Version Manager (NVM) installation for a specified list of users.
  - Configurable shell environment initialization (`.bashrc` by default).
  - Support for specifying different NVM versions per user.
  - Full `check_mode` support and strict user existence validation.

### Fixed
- `netfilter`: Prevent systemd race condition for legacy ipset unit by flushing handlers immediately after unit creation.

## [1.1.0] - 2026-02-19

### Added
- Production-ready role: `netfilter`:
  - Installation of `netfilter-persistent`, `iptables-persistent`, and `ipset-persistent`.
  - Declarative configuration of `ipsets` and `iptables` rulesets for IPv4 and IPv6.
  - Systemd fallback mechanism for `ipset` loading on legacy distributions (Xenial, Bionic).
  - Granular handling of package availability across different Ubuntu releases.

## [1.0.0] - 2025-12-26

### Added
- First production-ready role: `garagehq`:
  - Installation and systemd management of Garage HQ server.
  - Secure, idempotent configuration management using `garage.toml`.
  - RPC secret handling via `rpc_secret_file` with safe defaults.
- Role-level documentation and inclusion in roles index.
- Release workflow and roles documentation (`docs/release.md`, `docs/roles.md`).

## [0.0.1] - 2025-12-24

### Added
- Initial Ansible collection skeleton.
- `galaxy.yml` with metadata, tags, and licensing.
- Runtime compatibility declaration (`ansible-core >= 2.18.0`).
- Base repository structure (`roles/`, `plugins/`, `docs/`).
- MIT license and project README.
- ansible-lint configuration aligned with production profile.
