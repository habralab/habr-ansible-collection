# PHP

Installs and configures one or more co-installable PHP versions on Ubuntu.
The role owns versioned CLI/FPM include files and explicitly selects the
system-wide CLI alternatives. It does not rewrite packaged `php.ini` or files
under `mods-available`.

## Variables

- `php_repository`: `ubuntu`, `ppa_ondrej`, or `unmanaged` (default: `ubuntu`).
- `php_repository_manage`: manage the selected external repository (default:
  `true`).
- `php_versions`: mapping keyed by quoted `major.minor` versions.
- `php_cli_default_version`: version selected for `/usr/bin/php` and related
  alternatives. Required when a CLI SAPI is installed.

`extensions` contains Debian package suffixes: `mysql` installs
`php<version>-mysql`, while `xml` installs `php<version>-xml`.

`required_extensions` optionally verifies extensions after package and
configuration changes. Map an extension to its exact runtime version, or to an
empty string when only successful loading matters. The check uses the selected
version's CLI binary and runs once with the CLI configuration and, when enabled,
once with the FPM configuration. It requires the `cli` SAPI and is skipped in
Ansible check mode.

```yaml
php_repository: ubuntu
php_cli_default_version: "8.5"

php_versions:
  "8.5":
    sapis:
      - cli
      - fpm
    extensions:
      - curl
      - mbstring
      - mysql
    required_extensions:
      curl: ""
      redis: "6.3.0"
    cli_ini:
      date.timezone: UTC
    fpm_ini:
      date.timezone: UTC
      expose_php: "Off"
    fpm_default_pool_enabled: false
    fpm_pools:
      application:
        settings:
          user: web
          group: web
          listen: /run/php/php8.5-application.sock
          listen.owner: web
          listen.group: www-data
          listen.mode: "0660"
          pm: dynamic
          pm.max_children: "8"
          pm.start_servers: "2"
          pm.min_spare_servers: "1"
          pm.max_spare_servers: "3"
```

The Ubuntu archive provides its distribution PHP series. The Ondrej PPA is
accepted only on releases currently published by that PPA. Use `unmanaged`
when an operator or another role supplies an internal repository.
