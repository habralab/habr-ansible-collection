# Role: SSH Authorized Keys Development Notes

This document captures the intended design direction for a future `ssh_authorized_keys` role. It is intentionally limited to role goals, boundaries, and data model shape. It is not yet a public contract.

## Purpose

The role should provide a reusable, data-driven mechanism for managing SSH access through `authorized_keys`.

Target use cases:

- direct role usage in playbooks
- reuse as a low-level primitive via `include_role`
- materializing access policy for shared Unix accounts such as `root`, `web`, or `deploy`

## Scope

The role should manage:

- SSH public keys for Unix accounts
- grant, update, and revoke lifecycle
- one or more managed principals

The role should not manage:

- SSH daemon configuration
- SSH client configuration
- host keys
- user creation
- sudo policy

## Design Principles

- keep the role environment-agnostic
- keep access policy in inventory data, not in role files
- support both standalone and helper-style usage
- prefer explicit, iterable object models over ad hoc variables

## Conceptual Model

### Subject

A subject is an identity that owns one or more SSH public keys.

Examples:

- a person
- a CI actor
- an automation account

### Principal

A principal is a Unix account whose `authorized_keys` file is managed.

Examples:

- `root`
- `web`
- `deploy`

### Binding

A binding assigns one or more subjects to one principal.

## Candidate Public Data Shapes

Recommended model:

- `ssh_authorized_keys_subjects`
- `ssh_authorized_keys_bindings`

Optional simplified model:

- `ssh_authorized_keys_items`

The recommended direction is to treat SSH access as subject-to-principal binding rather than raw per-user key lists.

## Lifecycle Semantics

The role is expected to support:

- grant keys derived from declared subjects or direct items
- revoke keys that are explicitly absent or no longer bound
- additive mode for partially managed principals
- authoritative mode for fully managed principals

## Usage Modes

### Standalone Role

Inventory may define subjects and bindings directly, then apply the role in a play.

### Helper Role

Another role may compute subjects or bindings and call this role via `include_role`.

## Open Questions

- whether direct item mode should exist long-term or only during early adoption
- how authoritative mode should behave for mixed-ownership `authorized_keys`
- whether per-principal path overrides are worth supporting
- whether comments and metadata should be treated as part of managed identity
