# MariaDB role development

## Invariants

- `mariadb_version` is an explicit repository channel or series. The default is
  MariaDB's `12.rolling`; consumers may pin a `major.minor` series.
- The repository suite is the target host's real Ubuntu release.
- Generic repository/key behavior stays in `apt_repo`.
- Repository configuration is independently deployable and observable before
  package installation.
- Package installation must verify that the APT candidate belongs to the
  requested series before changing the host.
- Package files under `/etc/mysql` are never edited in place.
- Server overrides live only in `/etc/mysql/mariadb.conf.d/90-ansible.cnf` and
  are validated by the installed `mariadbd` option parser before a restart.
- `mariadb_config` mirrors the option-file structure: option group, directive,
  value. It recursively overrides the internal safe baseline. The role does
  not invent a variable for every server option.
- The common baseline carries every shared directive from the legacy custom,
  replication and Galera templates. Epoch overlays add version-specific
  directives. Topology features stay inactive until explicitly overridden by
  a consumer.
- Version differences are data overlays under `vars/config_*.yml`, not copied
  Jinja templates. Effective precedence is common baseline, detected epoch,
  then consumer `mariadb_config`.
- Database and account lifecycle remains in a separate sidecar role.

## Lifecycle stages

1. Repository and APT candidate verification.
2. Packages and pristine service inspection.
3. Validated server drop-in.
4. Databases and accounts.

Do not collapse these stages into a repository setup script or a single opaque
package task. Each stage must support check mode as far as its underlying APT
and service operations permit.

The service-state task is skipped in check mode because systemd cannot inspect
a unit whose package installation is only predicted. A real package-stage run
must install the unit and immediately enforce its enabled/running state.

MariaDB 12.3 does not expose a `--validate-config` option. The template module
therefore validates its temporary candidate with the installed server's
`--defaults-file=%s --verbose --help` parser. Using `--defaults-file` prevents
an obsolete currently-installed drop-in from poisoning validation of its
replacement. The role selects
`/usr/sbin/mariadbd` when available and falls back to `/usr/sbin/mysqld`, the
real server name before MariaDB 10.5. This parses the complete candidate's
server options, prints help and exits without starting another server process.

On a pristine-host check-mode run, package installation is only predicted and
no server parser exists yet. Configuration rendering is skipped until a real
package-stage run installs either supported server binary.
