# Locale

Declarative management of generated system locales and the default locale.

## Scope

- Ensure locale entries exist in `/etc/locale.gen`.
- Generate requested locales.
- Set the default system `LANG` in `/etc/default/locale`.

## Non-goals

- Timezone configuration.
- SSH or shell profile customization.
- Application-specific locale overrides.

## Variables

- `locale_generated`: List of locale entries in `/etc/locale.gen` format.
- `locale_default`: Default `LANG` value.

## Example

```yaml
locale_generated:
  - "en_US.UTF-8 UTF-8"
  - "ru_RU.UTF-8 UTF-8"

locale_default: "en_US.UTF-8"
```
