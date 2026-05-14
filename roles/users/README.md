# Users

Manages system and normal Linux users declaratively using a unified list.

## Scope

- Creation and removal of user accounts (`state: present|absent`).
- Management of primary and secondary groups.
- Configuration of user attributes (shell, UID, home directory).
- Removal of user home directories and mail spools when `remove: true` is set.
- Support for system users (`system: true`).
- Password hash injection.

## Non-goals

- SSH key management (handled by a dedicated role).
- `sudoers` configuration.
- Creation of groups (groups should exist or be created by another role).

## Configuration

The role is driven by a single variable `users_list`, which is a list of dictionaries.

### Variables

- `users_list`: List of users to manage (default: `[]`).
- User entries support the documented subset of `ansible.builtin.user` arguments used by this role, including `state`, `system`, `password`, `shell`, `create_home`, `remove`, `group`, `groups`, `append`, and `uid`.

### Example

```yaml
users_list:
  - name: "web"
    system: true
    shell: "/usr/sbin/nologin"
    create_home: false

  - name: "vadim"
    groups: "wheel,docker"
    append: true
    shell: "/bin/bash"
    password: "$6$rounds=656000$saltsalt$..." # Use password_hash filter

  - name: "old_employee"
    state: absent

  - name: "ubuntu"
    state: absent
    remove: true
```
