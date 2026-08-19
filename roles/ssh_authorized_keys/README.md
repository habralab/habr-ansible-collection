# SSH authorized keys

Manages SSH public keys for existing Unix users through a key catalog and
per-user contracts.

The role adds and removes only explicitly referenced keys. It does not use
exclusive mode, so keys outside the role's catalog remain untouched.

## Requirements

- ansible-core 2.16 or newer;
- the `ansible.posix` collection;
- target users normally exist before the role runs; missing users fail by
  default and can be explicitly skipped for housekeeping passes.

The collection declares `ansible.posix` as a transitive dependency. Consumers
installing `habr.linuxhost` with `ansible-galaxy` do not need to list it again.

## Scope

- maintain a reusable catalog of literal SSH public keys;
- group catalog entries under policy-oriented names;
- add or remove keys for multiple existing users;
- compose a common baseline with one inventory-specific overlay;
- preserve unrelated entries in `authorized_keys`.

## Non-goals

- creating Unix users;
- configuring `sshd` or SSH authentication policy;
- managing private keys;
- making the complete `authorized_keys` file exclusive to this role;
- merging an arbitrary number of inventory policy layers.

## Data model

`ssh_authorized_keys_catalog` maps stable key identifiers to complete literal
public keys:

```yaml
ssh_authorized_keys_catalog:
  primary_operator: >-
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExamplePrimaryKey operator@example.net
  deployment_key: >-
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExampleDeploymentKey deploy@example.net
```

`ssh_authorized_keys_groups` maps policy names to catalog identifiers:

```yaml
ssh_authorized_keys_groups:
  operators:
    - primary_operator
  deployers:
    - deployment_key
```

A user contract accepts four optional lists:

- `add_keys`: catalog identifiers to add;
- `remove_keys`: catalog identifiers to remove;
- `add_groups`: key groups to expand and add;
- `remove_groups`: key groups to expand and remove.

Unknown group and key identifiers, and identifiers resolved into both add and
remove lists for the same user, are rejected before key tasks run.

## Usage modes

Choose one of the following modes for a deployment. Do not mix a direct
contract with policy composition variables.

### Direct contract

Use `ssh_authorized_keys_contract` when the consumer has already assembled the
per-user policy:

```yaml
ssh_authorized_keys_catalog:
  primary_operator: >-
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExamplePrimaryKey operator@example.net

ssh_authorized_keys_contract:
  root:
    add_keys:
      - primary_operator
  application:
    add_keys:
      - primary_operator
```

### Baseline and inventory overlay

Use `ssh_authorized_keys_users_base` for policy shared by all hosts and
`ssh_authorized_keys_users_overlay` for the one effective specialization of a
host.

For example, `group_vars/all.yml` can contain the catalog, groups and common
baseline:

```yaml
ssh_authorized_keys_catalog:
  primary_operator: >-
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExamplePrimaryKey operator@example.net
  deployment_key: >-
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExampleDeploymentKey deploy@example.net

ssh_authorized_keys_groups:
  operators:
    - primary_operator

ssh_authorized_keys_users_base:
  root:
    add_groups:
      - operators
  application:
    add_groups:
      - operators
```

Then `group_vars/web_servers.yml` can specialize the application account:

```yaml
ssh_authorized_keys_users_overlay:
  application:
    add_keys:
      - deployment_key
```

The role recursively combines the user mappings and combines their lists with
Ansible's `append_rp` semantics. The resulting `application.add_keys` contains
the deployment key while the baseline operator group remains present.

Ansible resolves variables from the inventory before the role runs. Two
different group files defining `ssh_authorized_keys_users_overlay` are not
combined by this role: the higher-precedence value wins. Therefore each
effective overlay must be self-contained. See `DEVELOPMENT.md` for the detailed
inventory model.

### Revoking catalog keys

Removal uses the same catalog and group indirection:

```yaml
ssh_authorized_keys_catalog:
  retired_operator: >-
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExampleRetiredKey retired@example.net

ssh_authorized_keys_groups:
  revoked_keys:
    - retired_operator

ssh_authorized_keys_users_base:
  root:
    remove_groups:
      - revoked_keys
  application:
    remove_keys:
      - retired_operator
```

The catalog entry must remain available while a contract references it for
removal.

## Role invocation

```yaml
- name: Manage SSH authorized keys
  hosts: all
  roles:
    - role: habr.linuxhost.ssh_authorized_keys
```

## Variables

- `ssh_authorized_keys_catalog`: key identifier to literal public-key mapping;
  default `{}`.
- `ssh_authorized_keys_groups`: group identifier to list of key identifiers;
  default `{}`.
- `ssh_authorized_keys_contract`: directly supplied per-user contract; default
  `{}`.
- `ssh_authorized_keys_users_base`: common per-user policy; default `{}`.
- `ssh_authorized_keys_users_overlay`: effective inventory-specific per-user
  policy; default `{}`.
- `ssh_authorized_keys_manage_dir`: allow `ansible.posix.authorized_key` to
  create and manage each user's `.ssh` directory; default `true`.
- `ssh_authorized_keys_fail_on_missing_user`: fail when a contract references
  a Unix user that does not exist; default `true`. Set to `false` to log and
  skip all contracts for absent users while continuing with users present on
  the host.

When directory management is enabled, newly created SSH directories and
`authorized_keys` files receive ownership appropriate for the target user.

For broad housekeeping runs whose inventory policy can reference accounts not
present on every host:

```yaml
ssh_authorized_keys_fail_on_missing_user: false
```

Skipped usernames are emitted through an Ansible `debug` task at normal
verbosity. Their contracts are removed before group and key resolution.
