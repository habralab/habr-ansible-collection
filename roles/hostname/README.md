# Hostname (`hostname`)

Manage the persistent static hostname on Ubuntu. The role is opt-in and does
nothing by default.

When enabled, an empty `hostname_name` falls back to `inventory_hostname`.
The effective value must be a lowercase DNS-like static hostname no longer
than 64 characters. IP addresses and inventory aliases containing underscores,
spaces, ports, or other non-hostname characters are rejected before mutation.

The role intentionally does not manage `/etc/hosts` or DNS records.

## Variables

- `hostname_manage`: Enable hostname management; defaults to `false`.
- `hostname_name`: Explicit static hostname. An empty value uses
  `inventory_hostname`; defaults to `""`.
- `hostname_use`: `ansible.builtin.hostname` strategy; defaults to `systemd`.
- `hostname_cloud_init_preserve`: Value written as `preserve_hostname` when
  cloud-init is present; defaults to `true`.
- `hostname_cloud_init_config_dir`: Cloud-init configuration directory;
  defaults to `/etc/cloud/cloud.cfg.d`.
- `hostname_cloud_init_config_file`: Managed cloud-init override; defaults to
  `/etc/cloud/cloud.cfg.d/99-ansible-hostname.cfg`.
- `hostname_restart_cron`: Restart cron after an actual hostname change;
  defaults to `true`.
- `hostname_cron_service_name`: Cron systemd unit; defaults to `cron.service`.

The cloud-init override is skipped when its configuration directory is absent.
The cron handler is skipped when the service is not installed.

## Example

Use a valid inventory hostname without another host variable:

```yaml
- name: Manage hostnames
  hosts: all
  become: true
  roles:
    - habr.linuxhost.hostname
  vars:
    hostname_manage: true
```

Override an inventory alias that cannot be used as a static hostname:

```yaml
hostname_manage: true
hostname_name: web-01.example.net
```
