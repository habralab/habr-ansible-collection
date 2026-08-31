# PostgreSQL role development

Keep server lifecycle and database assets separate. This role may install and
configure one standalone package-managed cluster, but application databases,
roles and extensions belong to `postgres_assets`.

Do not template the complete package-owned `postgresql.conf` or `pg_hba.conf`.
Configuration tasks must remain a no-op unless their corresponding management
flag and a non-empty desired-state container are both supplied.

Use the collection APT repository helper. Do not invoke the upstream repository
setup shell script or derive exact PGDG package revisions.

Keep EOL versions separate from `postgres_supported_versions`. PostgreSQL 13 is
temporarily permitted for legacy convergence, but must remain visibly marked
and must not be presented as upstream-supported.

Never restart after writing managed configuration without a preflight. Use the
server parser for `postgresql.conf` and the running server's
`pg_file_settings`/`pg_hba_file_rules` views before flushing restart handlers.
