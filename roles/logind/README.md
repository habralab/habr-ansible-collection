# Logind

Manages `systemd-logind` configuration and user session states, specifically lingering for user-space systemd services.

## Scope

- Enabling and disabling systemd lingering for specific users via `loginctl`.
- Ensures immediate activation of `systemd --user` processes upon enabling.

## Non-goals

- Management of user creation (use the `users` role instead).
- Deployment of user-space systemd units.

## Configuration

The role is driven by the `logind_linger_users` variable, which is a list of dictionaries.

### Variables

- `logind_linger_users`: List of users to configure lingering for (default: `[]`).

### Example

```yaml
logind_linger_users:
  - name: "user1"
    state: present  # Enables lingering (default)
  - name: "user2"
    state: absent   # Disables lingering
```
