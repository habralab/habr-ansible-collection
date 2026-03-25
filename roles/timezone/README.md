# Timezone

Declarative management of the system timezone.

## Scope

- Set the system timezone.
- Keep `/etc/timezone` and `/etc/localtime` aligned with the declared value.

## Non-goals

- NTP configuration.
- Locale configuration.
- Hardware clock policy.

## Variables

- `timezone_name`: Target timezone name, for example `Europe/Lisbon`.

## Example

```yaml
timezone_name: "Europe/Lisbon"
```
