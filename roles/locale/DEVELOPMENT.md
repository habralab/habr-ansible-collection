# Role: Locale Development Notes

This role manages generated locales and the default system locale.

## Intended Contract

- public variable prefix: `locale_`
- `locale_generated` describes locale entries to materialize in `/etc/locale.gen`
- `locale_default` describes the default `LANG`

## Design Notes

- keep the role Ubuntu-focused and reproducible
- validate structure and basic syntax early
- avoid shipping a hardcoded locale registry
- prefer post-apply validation over trying to pre-enumerate every valid locale

## Non-goals

- timezone
- keyboard layout
- shell prompt or profile customization
- application-specific locale environment
