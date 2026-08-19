# Changelog

## [Unreleased]

## [2.2.0] - 2026-08-19

### Added
- `hostname`: Opt-in persistent Ubuntu hostname management with validated
  inventory fallback, cloud-init preservation, and cron restart handling.

## [2.1.0] - 2026-08-19

### Added
- `geoip_maxmind`: Install `geoipupdate`, manage MaxMind credentials and
  database editions, and bootstrap missing databases without nginx coupling.
- `mongodb`: Install MongoDB Community Server with optional authorization and
  single-member replica-set bootstrap.
- `mongodb_assets`: Manage MongoDB application users, role assignments, and
  authentication restrictions without creating or dropping application data.

### Changed
- `systemd_unit`: Manage unit drop-ins and render and validate timer units
  directly from the YAML model in both system and user scopes.
- `ssh_authorized_keys`: Optionally report and skip contracts for Unix users
  absent from a host during broad housekeeping passes.
- `collection`: Declare the `community.mongodb` dependency used by the MongoDB
  roles.

## [2.0.0] - 2026-08-14

### Breaking Changes
- Replace the standalone `nvm` role and `nvm_users` contract with the
  runtime-oriented `nodejs` role and `nodejs_runtimes` contract.
- Rename the `logind` role to `systemd_logind` and
  `logind_linger_users` to `systemd_logind_linger_users`.

### Added
- `nodejs`: Provision user-scoped NVM/Node.js runtimes and runtime-bound npm
  packages, exposing resolved executable paths for downstream automation.
- `systemd_unit` and `systemd_units`: Manage declarative system and user unit
  files, lifecycle operations, daemon reloads, and multi-unit iteration.
- `ssh_authorized_keys`: Compose authorized keys from catalogs, groups, direct
  entries, and per-user overlays.
- `nginx`: Add data-driven package, layout, drop-in, virtual host, upstream,
  cache, map, geo, authentication, FastCGI, and logrotate management.
- `mariadb`: Install and configure MariaDB Community Server.
- `mariadb_assets`: Manage MariaDB databases and application accounts.
- `php`: Install and configure parallel PHP CLI and FPM versions.
- `redis`: Manage Redis Server and optional Sentinel while preserving package
  defaults.

### Changed
- `apt_repo`: Use modern repository key handling while isolating legacy
  `apt-key` compatibility and making repository cleanup reliable.
- `haproxy`: Add optional global `tune.bufsize` configuration.
- `netfilter`: Require explicit permission before replacing UFW and extend
  package support to newer Ubuntu releases.
- `users`: Support explicit user home directories.
- `locale`, `packages`, `timezone`, and `users`: Declare Ubuntu Resolute
  support.
- `ci`: Add top-level lint and role-test entry points across Ansible core
  2.16 through 2.20.
- `collection`: Declare bounded dependencies on `ansible.mariadb`,
  `ansible.posix`, and `community.general`.

### Fixed
- `locale`: Preserve the distribution-managed mode when `/etc/default/locale`
  is a symlink.

## [1.9.0] - 2026-05-20

### Added
- Production-ready role: `dell_openmanage`:
  - Configure Dell OpenManage community APT repositories for Dell iSM.
  - Select the repository by PowerEdge generation and Ubuntu release.
  - Install `dcism` and manage `dcismeng.service`.
  - Document the supported release matrix against Dell repository availability data.

## [1.8.0] - 2026-05-15

### Added
- `users`: Support removing user home directories and mail spools via `remove: true`.

## [1.7.1] - 2026-03-25

### Fixed
- `locale`: Skip runtime locale availability post-checks in `check_mode`.

## [1.7.0] - 2026-03-25

### Added
- `locale`: Add a declarative role for managing generated locales and default `LANG`.
- `timezone`: Add a declarative role for managing the system timezone.

### Changed
- `docs`: Refine collection contribution guidance and role development notes.

## [1.6.0] - 2026-03-06

### Added
- `apt_repo`: Support for "flat" repositories (automatically detected by a trailing slash in the `suite` parameter).

### Changed
- `apt_repo`: Internal refactoring. Moved complex Jinja2 formatting to `vars/main.yaml` for better maintainability and readability.
- `apt_repo`: Improved GPG key and architecture string construction for both legacy and deb822 formats.

### Fixed
- `ci`: Updated collection build ignore list to exclude unnecessary metadata from the artifact.

## [1.5.1] - 2026-03-02

### Fixed
- `haproxy_sidecar`: Fix HAProxy syntax error by removing spaces in `expect status` lists.

## [1.5.0] - 2026-03-02

### Added
- Production-ready role: `haproxy_sidecar`:
  - Introduce `conf.d` based sidecar provisioning for HAProxy on the loopback interface.
  - Add dynamic template for `50-<service>.cfg` generation.
  - Implement automated cleanup of orphaned sidecar configurations.
  - Add default fallback timers for health checks.
  - Add comprehensive documentation with real-world examples.
- `haproxy`: Add native stats and Prometheus metrics support.
  - Introduce `haproxy_stats_*` variables to `defaults/main.yml`.
  - Deploy `10-stats.cfg` into `conf.d` when `haproxy_stats_enabled: true`.
  - Ensure idempotent removal of stats config when disabled.

## [1.4.0] - 2026-03-02

### Added
- Production-ready role: `haproxy`:
  - Install HAProxy from upstream PPA with dynamic version mapping based on Ubuntu release.
  - Idempotent `conf.d` directory support for modular sidecar configurations.
  - Standardized base configuration aligned with upstream Ubuntu packages.

### Fixed
- `apt_repo`: Replaced top-level `ansible_distribution_*` variables with explicit `ansible_facts` dictionary.

## [1.3.0] - 2026-02-24

### Added
- Production-ready role: `apt_repo`:
  - Helper role to manage legacy and deb822 APT repositories.
- Production-ready role: `packages`:
  - Base utility role for declarative management of APT packages and .deb URLs.
  - Integrates with the new `apt_repo` role for custom repository configuration.
- Production-ready role: `logind`:
  - Manage `systemd-logind` user lingering.
  - Utilizes `loginctl` with `creates/removes` for immediate D-Bus activation and idempotency.

### Changed
- `core`: Lowered minimum required `ansible-core` version to `>= 2.16.0`.
- `docs`: Consolidated documentation into `README.md` and `CONTRIBUTING.md`.
- `ci`: Implemented `tox` test matrix for automated linting across Ansible core versions 2.16 through 2.20.

### Fixed
- `nvm`: Resolved `ansible-lint` `name[template]` violations.
- `users`: Added Xenial and Bionic to supported Ubuntu versions in role metadata.

## [1.2.1] - 2026-02-20

### Fixed
- `nvm`: Suppress Git diff output during repository cloning to reduce task noise in playbooks.

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
