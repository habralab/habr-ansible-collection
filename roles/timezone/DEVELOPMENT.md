# Role: Timezone Development Notes

This role manages one narrow system concern: the configured timezone.

## Intended Contract

- public variable prefix: `timezone_`
- main variable: `timezone_name`
- empty `timezone_name` means no-op

## Design Notes

- keep the role Ubuntu-focused and reproducible
- validate input early
- rely on zoneinfo presence instead of a hardcoded timezone registry
- manage both `/etc/timezone` and `/etc/localtime`

## Non-goals

- time synchronization
- locale handling
- RTC policy
