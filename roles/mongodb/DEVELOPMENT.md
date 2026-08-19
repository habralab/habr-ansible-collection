# MongoDB role development notes

The old `ansible-linuxhost` role is provenance, not an implementation template.
Do not restore `apt_key`, unconditional client/tool installation, or the
unversioned exporter download.

## Invariants

- Validate distro/version/architecture/kernel before repository changes.
- Keep upstream certification separate from signed repository availability.
- Do not infer server availability from an APT Release file; inspect package
  indexes for mongodb-org-server on every added suite and architecture.
- Render operator overrides first; apply role-owned replication and security
  fields last.
- Keep configuration ownership explicit. Default execution must not rewrite
  package configuration, remove a keyfile, or remove a systemd drop-in.
- Delegate systemd drop-in materialization and lifecycle to `systemd_unit`;
  MongoDB owns only the decision to request its compatibility drop-in.
- Never place administrator passwords or keyfile contents in command arguments
  or normal Ansible output.
- Bootstrap only one replica-set member. A future multi-member reconciler must
  be a separate topology concern rather than an expanded loop here.

## Authorization bootstrap

MongoDB's localhost exception permits `replSetInitiate`, status inspection, and
creation of the first user while access control is enabled and no users exist.
The order is therefore fixed:

1. Deploy keyfile and final authorization/replication configuration.
2. Start or restart `mongod`.
3. Initiate the one-member replica set when it is uninitialized.
4. Wait for PRIMARY.
5. Create the first administrator.
6. Verify an authenticated ping.

If authentication fails on a deployment that already has users, first-user
creation also fails closed. Do not add password rotation semantics without an
explicit contract and tests for existing authenticated deployments.
