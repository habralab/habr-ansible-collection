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
