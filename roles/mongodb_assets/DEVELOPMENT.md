# MongoDB Assets Role Development Notes

## Invariants

- Validate the complete nested contract before installing packages or changing
  MongoDB state.
- Database entries are logical namespaces. Never create dummy collections or
  documents and never add database deletion semantics to `state: absent`.
- User identity is `name@database`; duplicate databases and duplicate names
  within one database are invalid.
- Pass explicit role mappings through unchanged. The upstream module compares
  role sets without treating ordering as semantic.
- Omitted authentication restrictions normalize to an empty desired list,
  matching `community.mongodb.mongodb_user` 1.8 behavior.
- Keep validation and mutation tasks that see credentials under `no_log`.
- Empty `mongodb_assets` is a full no-op, including dependency installation.
- Never shell out to `mongosh` for ordinary reconciliation.

## Password Semantics

The upstream module cannot compare a supplied password with MongoDB's stored
credential. `on_create` is therefore the role default and still permits roles
and authentication restrictions to converge. `always` is deliberately noisy
and exists only for an operator-controlled rotation.

Do not introduce local password hashes or revision markers without defining a
separate source-of-truth, failure, and recovery contract.

## Dependency Boundary

`community.mongodb` 1.8 adds declarative authentication restrictions and
supports this collection's Ansible core floor. Its `mongodb_user` module
requires PyMongo 4 or newer on the target. Package names alone cannot guarantee
that requirement across all Ubuntu releases, so the role probes the imported
driver version before invoking the module.
