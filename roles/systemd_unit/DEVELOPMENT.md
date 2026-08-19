# Systemd Unit Role Development Notes

## Artifact Ownership

- Without `drop_in`, the role owns the unit file and its removal lifecycle.
- With `drop_in`, the role owns only one drop-in file. The parent unit is an
  external lifecycle target and is never stopped, disabled, unmasked, or
  removed merely because the drop-in is absent.
- File changes reload the appropriate manager before an optional parent-unit
  reload or restart.
- Check mode skips lifecycle transitions that depend on a simulated file
  change because the manager still sees the old filesystem state.
- All source modes are shared by unit files and drop-ins.

## Timer Models

- Full model-backed `.timer` units require a non-empty `Timer` section and at
  least one activation trigger. Timer drop-ins may inherit parent triggers.
- Repeatable triggers normalize a scalar string to a one-item list before
  rendering, while preserving explicitly ordered lists.
- Native YAML booleans normalize to systemd `yes` or `no` values.
- Timer lifecycle remains generic: enable/start/restart operations target the
  `.timer`; the paired service is a separate declaration.
