# MongoDB Assets

Manages application users and their database-scoped role assignments on an
existing MongoDB deployment. Server installation, `mongod` configuration,
replica-set bootstrap, and creation of the first administrator remain in
`habr.linuxhost.mongodb`.

A MongoDB database is a logical namespace. This role does not create dummy
collections or documents to make an empty database visible in
`listDatabases`; application code or a separate migration process materializes
data.

## Requirements

- An already-running MongoDB server with authorization enabled.
- An existing administrative account permitted to inspect and manage users.
- `community.mongodb >=1.8.0,<2.0.0`, declared by this collection.
- PyMongo 4 or newer in the target Ansible Python environment.

The default `python3-pymongo` package satisfies the driver requirement only on
distributions that package PyMongo 4 or newer. On older distributions,
override `mongodb_assets_python_packages` and arrange a compatible driver in
the same Python environment used by Ansible. The role probes both importability
and version before connecting to MongoDB.

## Variables

- `mongodb_assets_python_packages`: Target packages providing PyMongo
  (default: `[python3-pymongo]`). Set an empty list only when PyMongo is
  provisioned externally in the target Ansible Python environment.
- `mongodb_assets_login_host`: MongoDB endpoint (default: `127.0.0.1`).
- `mongodb_assets_login_port`: MongoDB port (default: `27017`).
- `mongodb_assets_login_database`: Administrative authentication database
  (default: `admin`).
- `mongodb_assets_login_user`: Existing administrative user; no usable default.
- `mongodb_assets_login_password`: Administrative password; no usable default.
- `mongodb_assets_replica_set`: Optional replica-set name. When set, the module
  discovers the writable primary instead of assuming the inventory host is it.
- `mongodb_assets`: Database-to-user contracts (default: `[]`).

An empty `mongodb_assets` list is a full no-op and does not install the Python
driver. Credentials should come from Ansible Vault or another deployment
secret store.

## Contract

Each database entry accepts only:

- `database`: Required non-empty application and authentication database name.
- `state`: Required and currently limited to `present`.
- `users`: Required list, which may be empty.

The database entry declares a namespace but does not independently create or
drop it. Removing an entry does not remove undeclared users or data.

Each user entry accepts:

- `name`: Required non-empty user name.
- `state`: `present` or `absent`.
- `password`: Required and non-empty for `present`; forbidden for `absent`.
- `roles`: Required non-empty list for `present`; each role must be an explicit
  `{role, db}` mapping.
- `update_password`: `on_create` by default; `always` is an explicit rotation
  request.
- `authentication_restrictions`: Optional list of mappings containing
  `clientSource` and/or `serverAddress` string lists.

Omitting `authentication_restrictions` means the desired restriction list is
empty. Consequently, a later role or restriction change also removes
previously configured restrictions. Use an explicit list whenever restrictions
must remain present.

MongoDB identifies accounts as `name@database`; network origin is not part of
the account identity. The role grants no implicit privileges. In particular,
it does not default to `readWrite` or any administrative role.

## Example

```yaml
mongodb_assets_login_host: 127.0.0.1
mongodb_assets_login_database: admin
mongodb_assets_login_user: automation-admin
mongodb_assets_login_password: "{{ vault_mongodb_admin_password }}"
mongodb_assets_replica_set: application-rs

mongodb_assets:
  - database: application
    state: present
    users:
      - name: application
        state: present
        password: "{{ vault_application_mongodb_password }}"
        roles:
          - role: readWrite
            db: application
        authentication_restrictions:
          - clientSource:
              - 127.0.0.1
              - ::1
```

The corresponding URI is conceptually:

```text
mongodb://application:<password>@127.0.0.1:27017/application?authSource=application&replicaSet=application-rs
```

Cross-database roles remain explicit:

```yaml
mongodb_assets:
  - database: reporting
    state: present
    users:
      - name: reporting-worker
        state: present
        password: "{{ vault_reporting_mongodb_password }}"
        roles:
          - role: readWrite
            db: reporting
          - role: read
            db: application
```

## Password Rotation

MongoDB cannot compare a supplied plaintext password with the stored
credential. `update_password: on_create` therefore preserves idempotency and
does not rotate an existing password. For a controlled rotation, update the
secret, temporarily set `update_password: always`, apply once, then restore
`on_create`. Leaving `always` enabled reports a change on every run.

## User Removal

Removing a user does not drop its database, collections, or data:

```yaml
mongodb_assets:
  - database: application
    state: present
    users:
      - name: retired-worker
        state: absent
```

## Check Mode

On a prepared target, the module predicts user, role, and authentication
restriction changes without applying them. On a first check-mode run, package
installation is predicted but the role cannot inspect MongoDB until PyMongo is
actually installed; it reports that boundary and skips user reconciliation.

## Tags

- `mongodb_assets`
- `mongodb_assets_packages`
- `mongodb_assets_users`

## Non-goals

- Installing or configuring MongoDB server packages.
- Creating the first administrative account.
- Initiating or reconfiguring replica sets or sharded clusters.
- Creating or dropping databases, collections, or application data.
- Dump, restore, migration, or seed lifecycle.
- Implicit password rotation.

## References

- https://docs.ansible.com/ansible/latest/collections/community/mongodb/mongodb_user_module.html
- https://www.mongodb.com/docs/manual/reference/built-in-roles/
- https://www.mongodb.com/docs/manual/reference/command/usersInfo/
