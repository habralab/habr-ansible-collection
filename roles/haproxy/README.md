# HAProxy (`haproxy`)

Base role to install and configure the HAProxy server. It sets up the upstream PPA repository, installs the required packages, and provides a modern, modular configuration structure using `conf.d`.

## Scope

- Dynamically resolves and installs the appropriate HAProxy version based on the Ubuntu release (e.g., 3.0 for Jammy, 3.3 for Noble).
- Manages the upstream HAProxy APT repository using the internal `apt_repo` helper.
- Deploys a standardized, upstream-aligned base `haproxy.cfg` containing only `global` and `defaults` sections.
- Configures the systemd unit to include all configurations from the `/etc/haproxy/conf.d/` directory, enabling a modular "sidecar" architecture.

**Out of Scope:** This role does not configure specific `frontend`, `backend`, or `listen` blocks. These should be deployed by dependent sidecar roles directly into the `conf.d` directory.

## Variables

### Service & Installation
- `haproxy_version`: The HAProxy version to install. By default, it is dynamically resolved from `haproxy_version_matrix` based on the OS release.
- `haproxy_packages`: List of packages to install (default: `["haproxy"]`).
- `haproxy_service_enabled`: Whether the service should start on boot (default: `true`).
- `haproxy_service_masked`: Whether the service should be masked (default: `false`).

### Configuration Management
- `haproxy_manage_config`: If `true`, deploys the base `/etc/haproxy/haproxy.cfg` file (default: `true`).
- `haproxy_manage_confd`: If `true`, creates the `/etc/haproxy/conf.d/` directory and configures the systemd daemon to read from it via `EXTRAOPTS` (default: `true`).

### Global SSL Settings (Aligned with Mozilla Intermediate Profile)
These variables populate the global `ssl-default-bind-*` directives in the base configuration:
- `haproxy_global_ssl_ca_base`: Default CA base directory (default: `/etc/ssl/certs`).
- `haproxy_global_ssl_crt_base`: Default CRT base directory (default: `/etc/ssl/private`).
- `haproxy_global_ssl_ciphers`: List of default bind ciphers.
- `haproxy_global_ssl_ciphersuites`: List of default bind cipher suites (TLS 1.3).
- `haproxy_global_ssl_options`: List of SSL options (default: `["ssl-min-ver TLSv1.2", "no-tls-tickets"]`).

### Statistics / Metrics Configuration
Configures a dedicated frontend for HAProxy stats and Prometheus metrics (deployed as `conf.d/10-stats.cfg`).
- `haproxy_stats_enabled`: Enable the stats frontend (default: `false`).
- `haproxy_stats_bind`: Address and port to bind the stats frontend (default: `*:8404`).
- `haproxy_stats_path`: URI path for the HTML stats page (default: `/stats`).
- `haproxy_stats_refresh`: Auto-refresh interval for the HTML page (default: `10s`).
- `haproxy_stats_prometheus_enabled`: Expose Prometheus metrics natively (default: `true`, requires HAProxy 2.0+).
- `haproxy_stats_prometheus_path`: URI path for Prometheus metrics (default: `/metrics`).

## Example

```yaml
- name: Setup HAProxy Base
  hosts: loadbalancers
  roles:
    - name: habr.linuxhost.haproxy
      vars:
        haproxy_manage_confd: true
```
