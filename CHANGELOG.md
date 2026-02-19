# Changelog

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
