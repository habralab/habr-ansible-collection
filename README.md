# Habr Ansible Collection

This repository contains the **Habr Ansible Collection**, providing reusable roles,
plugins, and modules for managing Linux hosts and infrastructure services.

## Structure

- `roles/` — production-ready Ansible roles
- `plugins/` — custom plugins (modules, filters, lookups)
- `docs/` — internal documentation and guidelines

## Requirements

- ansible-core >= 2.15

## Usage

Install the collection from git:

```bash
ansible-galaxy collection install git+https://github.com/habralab/habr-ansible-collection.git
```

Then reference roles using FQCN:

```yaml
roles:
  - habr.linuxhost.garagehq
```

This collection is maintained by the Habr infrastructure team.
