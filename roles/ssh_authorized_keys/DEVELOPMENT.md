# SSH authorized keys role design

This document describes the internal policy-composition model and invariants.
The public variables and usage examples are documented in `README.md`.

## Processing pipeline

The role separates reusable identities, inventory policy and host mutation:

```text
key catalog + key groups
            |
user baseline + one effective inventory overlay
            |
            v
      effective contract
            |
      target user filter
            |
      group expansion
            |
            v
  add_keys / remove_keys per user
            |
            v
 ansible.posix.authorized_key
```

Key identifiers keep inventory policy independent from literal public-key
payloads. Key groups provide reusable policy sets such as operators or revoked
keys without duplicating catalog entries.

## Contract boundary

There are two intended entry points:

1. Policy mode builds the effective contract from
   `ssh_authorized_keys_users_base` and
   `ssh_authorized_keys_users_overlay`.
2. Direct mode receives an already assembled
   `ssh_authorized_keys_contract`.

These are alternative ownership models, not three inventory precedence layers.
A consumer should not define a direct contract together with a non-empty base
or overlay.

The executor ultimately requires only per-user `add_keys` and `remove_keys`
lists containing catalog identifiers. Group references are expanded before
host mutation.

## Inventory precedence

The baseline and overlay names deliberately differ. This lets a common value
from `group_vars/all.yml` survive when a more specific group supplies an
overlay, without relying on Ansible's global `hash_behaviour=merge` setting.

Ansible resolves each variable before role execution. If both a parent group
and a child group define `ssh_authorized_keys_users_overlay`, the child's value
replaces the parent's value according to normal inventory precedence. The role
never sees both values and therefore cannot merge them.

Consequences:

- use one effective overlay per host;
- make a higher-precedence overlay self-contained;
- repeat inherited policy in a child overlay when it must remain effective;
- do not interpret `append_rp` as cross-group inventory merging.

Within the role, `append_rp` recursively combines the already resolved base and
overlay. List items supplied by the overlay are appended, while duplicate
items from the lower-precedence list are removed in favor of the overlay's
occurrence.

If a future consumer needs more than a baseline and one effective overlay, add
an explicit ordered list of policy fragments to the public model. Do not make
the role depend on implicit group load order or global hash merging.

## Validation invariants

Before key-management tasks begin:

- all top-level containers must be mappings;
- direct contract and base/overlay policy modes must not be mixed;
- catalog entries must be non-empty literal public-key strings;
- key groups must contain only known catalog identifiers;
- missing target Unix users must either fail validation or be explicitly
  reported and filtered according to `ssh_authorized_keys_fail_on_missing_user`;
- user contracts must contain only the four documented fields;
- user contract fields must be lists;
- every referenced key group must exist;
- every resolved key identifier must exist in the catalog;
- the same key identifier must not be present in both add and remove sets for
  one user.

New contract fields or composition layers must preserve validation before
mutation and must define deterministic merge behavior.

## Mutation model

The role manages only explicitly referenced catalog keys. It intentionally
leaves `exclusive` disabled so that adopting the role does not remove keys
owned by another system or keys not yet represented in the catalog.

Users are normally expected to be provisioned before this role. Broad
housekeeping passes may set `ssh_authorized_keys_fail_on_missing_user` to
`false`; absent users are then reported and removed from the effective contract
before group expansion. Directory creation and ownership management for
remaining users are delegated to `ansible.posix.authorized_key` and are
controlled by `ssh_authorized_keys_manage_dir`.

The catalog stores literal public keys. Supporting remote URLs or controller
file paths would introduce a different trust and transport model and should be
designed explicitly rather than added as an incidental input form.
