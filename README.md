# Habr Ansible Collection

This repository contains the **Habr Ansible Collection**, providing reusable roles,
plugins, and modules for managing Linux hosts and infrastructure services.

## Requirements

- ansible-core >= 2.16.0

## Installation

Install the collection via `requirements.yml`:

```yaml
collections:
  - name: habr.linuxhost
    source: git+https://github.com/habralab/habr-ansible-collection.git
    type: git
    version: main
```

Or directly from CLI:

```bash
ansible-galaxy collection install git+https://github.com/habralab/habr-ansible-collection.git
```

## Available Roles

Detailed documentation for each role is available in its respective `roles/<name>/README.md`.

Some roles may also include a role-local `DEVELOPMENT.md` with internal design notes and contributor guidance for that specific role.

- `apt_repo`: Helper role to manage APT repositories (supports legacy lists and deb822 sources).
- `dell_openmanage`: Configures Dell OpenManage iSM APT repository and installs Dell iSM packages.
- `haproxy`: Installs HAProxy and configures modular `conf.d` directory structure.
- `garagehq`: Installs and configures [Garage](https://garagehq.deuxfleurs.fr/) S3-compatible storage.
- `locale`: Declarative management of generated system locales and default `LANG`.
- `systemd_logind`: Manages `systemd-logind` configuration and user lingering.
- `netfilter`: Declarative `iptables` and `ipset` management via `netfilter-persistent`.
- `nvm`: Multi-user Node Version Manager (NVM) installation from git.
- `packages`: Declarative management of APT packages and .deb URLs.
- `timezone`: Declarative management of the system timezone.
- `users`: Declarative management of Linux users (UIDs, shells, groups).

## Usage Example

Reference roles using FQCN:

```yaml
- name: Setup Web Server
  hosts: web_servers
  roles:
    - name: habr.linuxhost.users
      vars:
        users_list: [{ name: "web", groups: ["www-data"] }]
    - name: habr.linuxhost.nvm
      vars:
        nvm_users: [{ name: "web" }]
```

## Principles

- **Idempotency**: Roles are designed to be safe to run repeatedly.
- **Explicit Scope**: Each role should define clear operational boundaries and documented non-goals.
- **Pragmatic Modeling**: Simple use cases should stay simple, but more complex infrastructure roles may use richer internal models when this reduces drift and improves operability.
- **Transparency**: Public role contracts belong in role `README.md`; implementation-specific design rules may live in role-local `DEVELOPMENT.md`.

This collection is maintained by **Habr infrastructure team**. For development guidelines, see [CONTRIBUTING.md](./CONTRIBUTING.md).
