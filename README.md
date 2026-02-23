# Habr Ansible Collection

This repository contains the **Habr Ansible Collection**, providing reusable roles,
plugins, and modules for managing Linux hosts and infrastructure services.

## Requirements

- ansible-core >= 2.15

## Installation

Install the collection via `requirements.yml`:

```yaml
collections:
  - name: habr.linuxhost
    source: git+ssh://git@git.habralab.com/tools/habr-ansible-collection.git
    type: git
    version: main
```

Or directly from CLI:

```bash
ansible-galaxy collection install git+ssh://git@git.habralab.com/tools/habr-ansible-collection.git
```

## Available Roles

Detailed documentation for each role is available in its respective `roles/<name>/README.md`.

- `garagehq`: Installs and configures [Garage](https://garagehq.deuxfleurs.fr/) S3-compatible storage.
- `netfilter`: Declarative `iptables` and `ipset` management via `netfilter-persistent`.
- `nvm`: Multi-user Node Version Manager (NVM) installation from git.
- `packages`: Declarative management of APT packages and .deb URLs.
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

- **Idempotency**: All roles are safe to run multiple times.
- **Minimalism**: Roles do one thing well with clear non-goals.
- **Transparency**: Explicit secret handling and upstream documentation references.

This collection is maintained by **Habr infrastructure team**. For development guidelines, see [CONTRIBUTING.md](./CONTRIBUTING.md).
