# PostgreSQL role development

Keep server lifecycle and database assets separate. This role may install and
configure one standalone package-managed cluster, but application databases,
roles and extensions belong to `postgres_assets`.

Do not template the complete package-owned `postgresql.conf` or `pg_hba.conf`.
Configuration tasks must remain a no-op unless their corresponding management
flag and a non-empty desired-state container are both supplied.

Use the collection APT repository helper. Do not invoke the upstream repository
setup shell script or derive exact PGDG package revisions.
