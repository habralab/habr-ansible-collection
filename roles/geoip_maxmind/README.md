# MaxMind GeoIP (`geoip_maxmind`)

Installs Ubuntu's `geoipupdate` tooling, manages `/etc/GeoIP.conf`, and performs
the initial download of requested MaxMind GeoIP2 or GeoLite2 databases.

The role deliberately has no nginx integration or dependency. Consumers such
as nginx, PHP, or application services should reference the managed `.mmdb`
paths through their own configuration contracts.

## Requirements

- Ubuntu Focal, Jammy, Noble, or Resolute.
- A MaxMind account ID and license key when this role manages `GeoIP.conf`.
- HTTPS access to the configured MaxMind update endpoint.
- The Ubuntu component containing `geoipupdate` must already be enabled.

The Ubuntu package owns its regular update schedule (`cron` and, on newer
packages, systemd units). This role does not install a duplicate scheduler.

## Variables

| Variable | Default | Description |
| --- | --- | --- |
| `geoip_maxmind_packages` | `geoipupdate`, `libmaxminddb0`, `mmdb-bin` | Packages to install from enabled Ubuntu repositories. |
| `geoip_maxmind_package_state` | `present` | Package state: `present` or `latest`. |
| `geoip_maxmind_config_manage` | `true` | Manage the update configuration. |
| `geoip_maxmind_config_path` | `/etc/GeoIP.conf` | Configuration path used by `geoipupdate`. |
| `geoip_maxmind_account_id` | `""` | Numeric MaxMind account ID. |
| `geoip_maxmind_license_key` | `""` | MaxMind license key; keep it in Ansible Vault. |
| `geoip_maxmind_edition_ids` | Country, City | Database edition IDs to download. |
| `geoip_maxmind_database_directory` | `/usr/share/GeoIP` | Destination for `.mmdb` databases. |
| `geoip_maxmind_update_on_configure` | `true` | Download requested databases when any are missing. |
| `geoip_maxmind_config_no_log` | `true` | Hide configuration task data that may contain secrets. |
| `geoip_maxmind_host` | `""` | Optional update endpoint override. |
| `geoip_maxmind_proxy` | `""` | Optional proxy host and port. |
| `geoip_maxmind_proxy_user_password` | `""` | Optional proxy credentials. |
| `geoip_maxmind_preserve_file_times` | `false` | Preserve database modification times. |
| `geoip_maxmind_lock_file` | `""` | Optional explicit updater lock path. |
| `geoip_maxmind_retry_for` | `""` | Optional updater retry duration, such as `5m`. |

## Example

```yaml
- name: Install MaxMind GeoLite databases
  hosts: geoip_hosts
  become: true
  roles:
    - role: habr.linuxhost.geoip_maxmind
      vars:
        geoip_maxmind_account_id: "{{ vault_maxmind_account_id }}"
        geoip_maxmind_license_key: "{{ vault_maxmind_license_key }}"
        geoip_maxmind_edition_ids:
          - GeoLite2-Country
          - GeoLite2-City
          - GeoLite2-ASN
```

The resulting files are `/usr/share/GeoIP/GeoLite2-Country.mmdb`,
`/usr/share/GeoIP/GeoLite2-City.mmdb`, and
`/usr/share/GeoIP/GeoLite2-ASN.mmdb`.

## Lifecycle and check mode

- Package installation and configuration rendering are idempotent.
- Initial download runs only while at least one requested database is absent.
- Check mode reports that missing databases would be downloaded without using
  the MaxMind credentials or changing the host.
- Set `geoip_maxmind_config_manage: false` to use an externally managed
  `GeoIP.conf`; initial update can remain enabled independently.

## Non-goals

- Installing nginx GeoIP2 modules.
- Generating nginx `geoip2` directives or reloading nginx.
- Replacing the update schedule shipped by Ubuntu's `geoipupdate` package.
