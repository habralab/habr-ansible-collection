# Systemd Unit

Declaratively manages one systemd unit file and its lifecycle in the system or
user manager scope.

## Scope

- Validate and normalize one unit declaration.
- Materialize a unit from YAML model, inline content, controller template, or
  controller file.
- Resolve system and user unit paths and execution contexts.
- Reload the appropriate manager after file changes.
- Converge enabled, masked, and service state.
- Stop, disable, remove, and reload when `state: absent`.
- Optionally delegate user lingering to `habr.linuxhost.systemd_logind`.

## Variables

- `systemd_unit_config`: Required non-empty unit declaration.
- `systemd_unit_manage_linger`: Default for automatic lingering management of
  user-scoped units (default: `false`).

## Unit Declaration

Required fields:

- `name`: Unit filename without path separators.
- `scope`: `system` or `user`.
- `state`: `present` or `absent`.
- `user`: Required for `scope: user`.

Optional lifecycle fields:

- `enabled`: Desired enablement state.
- `masked`: Desired mask state.
- `service_state`: `started`, `stopped`, `restarted`, or `reloaded`.
- `restart_on_change`: Restart the unit when its file changes.
- `reload_on_change`: Reload the unit when its file changes.
- `force`: Pass through to `ansible.builtin.systemd_service`.
- `no_block`: Pass through to `ansible.builtin.systemd_service`.
- `manage_linger`: Ensure lingering through `systemd_logind` before user
  lifecycle convergence.
- `mode`: Unit file mode as an octal string (default: `0644`).

`restart_on_change` and `reload_on_change` are mutually exclusive. If neither
is enabled, a changed file causes only `daemon-reload`; runtime state changes
only when `service_state` is explicitly set.

## Unit Sources

For `state: present`, `source` must define exactly one mode.

### YAML Model

```yaml
systemd_unit_config:
  name: "pm2-web.service"
  scope: "user"
  user: "web"
  state: "present"
  enabled: true
  service_state: "started"
  restart_on_change: true
  manage_linger: true
  source:
    model:
      Unit:
        Description: "PM2 for web"
        After:
          - "network.target"
      Service:
        Type: "simple"
        WorkingDirectory: "/srv/app"
        ExecStart:
          - "/home/web/.nvm/versions/node/current/bin/pm2-runtime start ecosystem.config.js"
        Restart: "always"
      Install:
        WantedBy:
          - "default.target"
```

Model mode intentionally supports a conservative subset of the `Unit`,
`Service`, and `Install` sections. Unsupported systemd syntax should use one of
the raw source modes.

### Inline Content

```yaml
source:
  content: |
    [Unit]
    Description=Example service

    [Service]
    ExecStart=/usr/local/bin/example
```

### Controller Template

```yaml
source:
  template: "example.service.j2"
```

The path follows the standard `ansible.builtin.template` controller-side
lookup rules. An absolute path may be used when the template is supplied by the
consumer rather than the collection role.

### Controller File

```yaml
source:
  src: "files/example.service"
```

The path follows the standard `ansible.builtin.copy` controller-side lookup
rules. An absolute path may be used for a consumer-owned unit file.

## Removal

No source is required for removal:

```yaml
systemd_unit_config:
  name: "example.service"
  scope: "system"
  state: "absent"
```

The role attempts to stop and disable the unit, removes its file, and reloads
the appropriate manager.

## Check Mode

When a unit file would change, manager lifecycle transitions are skipped because
the manager cannot load a file that check mode did not write. User-scoped
lifecycle requires an available `/run/user/<uid>` manager context; check mode
does not pretend that enabling lingering created this runtime directory.

## Non-goals

- User creation.
- Package or application deployment.
- PM2- or NVM-specific service semantics.
- Bulk iteration; use `habr.linuxhost.systemd_units` for multiple units.
- Exhaustive modeling of every systemd directive and unit type.
