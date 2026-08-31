# Systemd Unit

Declaratively manages one systemd unit file or drop-in and its lifecycle in the
system or user manager scope.

## Scope

- Validate and normalize one unit declaration.
- Materialize a unit or drop-in from YAML model, inline content, controller
  template, or controller file.
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
- `drop_in`: Optional safe `.conf` filename. When set, manage only that file in
  the parent unit's drop-in directory.

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

Drop-ins cannot set `enabled`, `masked`, or `force`: those fields express
ownership of the parent unit rather than ownership of one supplemental file.

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
        LimitNOFILE: 65536
        LimitNPROC: "4096:8192"
        LimitCORE: "infinity"
        ExecStart:
          - "/home/web/.nvm/versions/node/current/bin/pm2-runtime start ecosystem.config.js"
        Restart: "always"
      Install:
        WantedBy:
          - "default.target"
```

Model mode intentionally supports a conservative subset of the `Unit`,
`Service`, `Timer`, and `Install` sections. Unsupported systemd syntax should
use one of the raw source modes.

The `Service` model supports `PIDFile` and the `LimitNOFILE`, `LimitNPROC`, and
`LimitCORE` resource limits. Limits accept a non-negative YAML integer or a
non-empty systemd value such as `infinity` or `soft:hard`.

### Timer Model

Timer units use the same lifecycle and system/user scope contract as services.
The model requires a `.timer` unit name, a `Timer` section, and at least one
trigger for a full unit. A timer drop-in may inherit triggers from its parent.
Trigger directives accept either one string or a list of strings; boolean
directives use native YAML booleans.
Empty trigger values are rejected by the model. Use a raw source mode when a
drop-in intentionally needs systemd's empty-assignment reset semantics.

```yaml
systemd_unit_config:
  name: "geoipupdate.timer"
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
        Description: "Update MaxMind databases"
      Timer:
        OnCalendar:
          - "Wed *-*-* 06:00"
          - "Sun *-*-* 06:00"
        Persistent: true
        RandomizedDelaySec: "1h"
        Unit: "geoipupdate.service"
      Install:
        WantedBy:
          - "timers.target"
```

Supported triggers are `OnActiveSec`, `OnBootSec`, `OnStartupSec`,
`OnUnitActiveSec`, `OnUnitInactiveSec`, and `OnCalendar`. The model also
supports `AccuracySec`, `RandomizedDelaySec`, `OnClockChange`,
`OnTimezoneChange`, `Unit`, `Persistent`, `WakeSystem`, and
`RemainAfterElapse` across the supported Ubuntu matrix.

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

## Drop-ins

Set `drop_in` to manage a file below the parent unit's `.d` directory while
targeting lifecycle operations at the parent unit:

```yaml
systemd_unit_config:
  name: "mongod.service"
  drop_in: "habr-rseq.conf"
  scope: "system"
  state: "present"
  restart_on_change: true
  source:
    model:
      Service:
        Environment:
          - "GLIBC_TUNABLES=glibc.pthread.rseq=1"
```

The destination is `/etc/systemd/system/<name>.d/<drop_in>` for system scope
or `~/.config/systemd/user/<name>.d/<drop_in>` for user scope. Source modes,
manager reloads, and change-triggered parent reload/restart behave as for unit
files.

## Removal

No source is required for removal:

```yaml
systemd_unit_config:
  name: "example.service"
  scope: "system"
  state: "absent"
```

For a unit file, the role attempts to stop and disable the unit, removes its
file, and reloads the appropriate manager. For a drop-in, it removes only the
drop-in and never stops, disables, unmasks, or removes the parent unit. An
explicit `service_state` or change-triggered reload/restart may still target the
parent after manager reload.

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
- Exhaustive modeling of every systemd directive and unit type beyond services
  and timers.
