# Systemd Units

Thin iteration wrapper over `habr.linuxhost.systemd_unit` for managing multiple
declarative system or user units.

## Scope

- Validate that the wrapper input is a non-empty list.
- Preserve declaration order.
- Delegate each item to `habr.linuxhost.systemd_unit`.
- Propagate `systemd`, `systemd-unit`, and `systemd-units` tags to delegated
  tasks.

Validation, rendering, user context preparation, and the complete unit
lifecycle remain owned by `habr.linuxhost.systemd_unit`.

## Variables

- `systemd_units_items`: Ordered list of declarations accepted by
  `habr.linuxhost.systemd_unit`. The list must not be empty.

## Example

```yaml
systemd_units_items:
  - name: "example-system.service"
    scope: "system"
    state: "present"
    enabled: true
    service_state: "started"
    source:
      src: "files/example-system.service"

  - name: "pm2-web.service"
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
        Service:
          Type: "simple"
          ExecStart:
            - "/home/web/.nvm/versions/node/current/bin/pm2-runtime start ecosystem.config.js"
          Restart: "always"
        Install:
          WantedBy:
            - "default.target"
```

The wrapper processes declarations sequentially. Duplicate declarations are not
merged or deduplicated; operators should declare each effective unit once.
For a service/timer pair, declare the `.service` first and the `.timer` second.
The service normally needs only materialization, while the timer owns
`enabled: true` and `service_state: started`.

## Tags

- `systemd-units`: Run the wrapper and delegated unit tasks.
- `systemd-unit`: Run delegated single-unit tasks through the wrapper.
- `systemd`: Run the complete systemd-related path.

## Non-goals

- Independent single-unit schema or defaults.
- Rendering or lifecycle logic.
- Reordering, merging, or deduplicating declarations.
- Cross-unit transaction or rollback semantics.
