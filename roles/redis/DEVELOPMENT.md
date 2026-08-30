# Redis role development notes

The role was redesigned from the historical `ansible-linuxhost` Redis roles.
Do not copy their full `redis.conf` or `sentinel.conf` templates: they freeze
upstream defaults from one Redis generation and overwrite package conffiles.

Before adding Sentinel management, test bootstrap, a normal idempotent run,
peer discovery, `SENTINEL SET`, failover, and a later Ansible run. Runtime
epochs and discovered topology must survive that last run.

Keep exact package versions optional and expressed as complete Debian versions.
Do not derive distribution-specific package revisions from an upstream Redis
version. Apply one exact version consistently to server and Sentinel packages.
