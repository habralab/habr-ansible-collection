# Role: Nginx

Installs and configures Nginx using a layout-driven approach that supports the Ubuntu distribution packages, Ondrej PPA, and the official Nginx.org stable or mainline repositories.

The selected repository affects not only package origin and update cadence, but also the filesystem layout the role manages. Ubuntu and Ondrej use the familiar Debian-style structure with `sites-available` / `sites-enabled`, while Nginx.org uses the upstream-style layout centered around `conf.d`. In practice, this changes the default package set, runtime user, generated include paths, logrotate retention, and whether server configs are enabled through symlinks or rendered directly into the active directory.

## Scope

- Selects one active package source and automatically switches the filesystem layout between Debian-style (`sites-available` / `sites-enabled`) and upstream-style (`conf.d` only).
- Optionally manages APT repositories through the internal `apt_repo` helper role.
- Installs and removes packages, deploys the base `nginx.conf` and companion files, and validates configuration before reload/restart.
- Creates optional global HTTP drop-ins for proxy, gzip, and Real IP settings based on the variables you define.
- Manages server configs from a declarative `nginx_servers` list, including optional symlinks for Debian-style layouts.
- Prepares runtime directories, logrotate configuration, DH parameters, runtime group membership, and cleanup of obsolete paths.

**Out of Scope:** This role does not ship application-specific vhost templates beyond the built-in `default` and `status` examples. Custom websites should be provided as your own Jinja templates and referenced via `nginx_servers`.

## Variables

### Core Role Variables
| Variable | Default | Description |
|---|---|---|
| `nginx_repo_manage` | `true` | Whether the role should manage APT repositories. |
| `nginx_packages` | `[]` | Explicit list of packages to install. Overrides layout defaults. |
| `nginx_remove_packages` | `[]` | List of packages to purge before installation. |
| `nginx_repositories` | `{}` | Dictionary to configure/enable repositories (see overrides). |

### Repository Selection and Layouts

The role merges `nginx_repositories` with the built-in repository map and uses the first entry with `enabled: true` as the active source. If nothing is enabled, it falls back to the built-in `ubuntu` definition.

Built-in repository keys:
- `ubuntu`: distro packages, Debian-style layout, default package set `["nginx-full", "nginx"]`
- `ppa_ondrej`: Ondrej PPA, Debian-style layout, default package set `["nginx-full", "nginx"]`
- `nginx_org`: official stable upstream repository, upstream layout, default package set `["nginx"]`
- `nginx_org_mainline`: official mainline upstream repository, upstream layout, default package set `["nginx"]`

Supported repository item fields:

| Field | Description |
|---|---|
| `enabled` | Enables this repository candidate. The first enabled item becomes active. |
| `layout` | Selects the file layout (`debian` or `upstream`). |
| `packages` | Package list used when `nginx_packages` is empty. |
| `config` | Optional `apt_repo` definition used when `nginx_repo_manage: true`. |

Minimal override example:

```yaml
nginx_repositories:
  nginx_org_mainline:
    enabled: true
```

**NB:** Switching between repositories is supported, but it is not a no-op. Package contents, directory layout, generated include paths, runtime user, and default server placement may all change at once. This can be useful for semi-manual migrations from one packaging model to another, but it also means your overrides must be reviewed carefully or you may end up with duplicate vhosts, orphaned files, or configs rendered into the wrong path.

### IP Sets (Global Dictionaries)
A centralized, data-driven dictionary for managing IP prefixes across the infrastructure. This allows you to define networks once and reference them dynamically in Real IP, ACLs, and Geo modules.

| Variable | Default | Description |
|---|---|---|
| `nginx_ip_sets` | `undefined` | Global dictionary of IP lists. Keys are list names, values are lists of dicts containing `net` (required), `value` (optional, for geo maps and other places where implemented), and `remark` (optional, for comments). |

**Example configuration (`group_vars/all.yml`):**
```yaml
nginx_ip_sets:
  local:
    - net: "127.0.0.0/8"
      remark: "IPv4 Loopback"
    - net: "::1/128"
      remark: "IPv6 Loopback"
    - net: "fe80::/10"
      remark: "IPv6 Link-Local"

  private:
    - net: "10.0.0.0/8"
      remark: "Private - RFC 1918"
    - net: "172.16.0.0/12"
      remark: "Private - RFC 1918"
    - net: "192.168.0.0/16"
      remark: "Private - RFC 1918"
    - net: "fc00::/7"
      remark: "IPv6 ULA - RFC 4193"

  cdn:
    - net: "203.0.113.0/24"
    - net: "2001:db8::/32"

  office_vpn:
    - net: "192.0.2.0/24"
      remark: "Main office"

  botnets:
    - net: "198.51.100.0/24"
      value: "bot"
      remark: "Known bot network"
```

### Configuration Variables (Template Overrides)
These variables don't need to be defined unless you want to override the built-in layout defaults. If a variable is undefined, the **Role Default** is applied via templates. If the directive is omitted entirely, Nginx falls back to the **Nginx Default**.

#### Global / HTTP
Official Nginx documentation for the modules configured by this section:
* [Core functionality](https://nginx.org/en/docs/ngx_core_module.html)
* [HTTP Core module](https://nginx.org/en/docs/http/ngx_http_core_module.html)

| Variable | Role Default | Nginx Default | Description |
|---|---|---|---|
| `nginx_user` | layout specific | `nobody nobody` | Runtime user (usually `www-data` or `nginx`). |
| `nginx_worker_processes` | `auto` | `1` | Number of worker processes. |
| `nginx_pid_file` | `/run/nginx.pid` | `nginx.pid` | Path to the PID file. |
| `nginx_error_log` | `/var/log/nginx/error.log` | `logs/error.log` | Path to the error log. |
| `nginx_worker_connections` | `768` / `1024` | `512` | Worker connections. |
| `nginx_worker_rlimit_nofile`| `undefined` | `-` | Limit on the maximum number of open files (RLIMIT_NOFILE). |
| `nginx_mime_types` | `undefined` | `-` | Dictionary overriding or adding custom MIME types. Merges seamlessly with stock `mime.types` (e.g., `{"model/gltf+json": "gltf"}`). |
| `nginx_multi_accept` | `undefined` | `off` | Accept multiple connections per process. |
| `nginx_sendfile` | `true` | `off` | Enable sendfile. |
| `nginx_client_max_body_size` | `undefined` | `1m` | Sets the maximum allowed size of the client request body. |
| `nginx_client_body_buffer_size` | `undefined` | `8k|16k` | Sets buffer size for reading client request body. |
| `nginx_tcp_nodelay` | `undefined` | `on` | Enables or disables the use of the `TCP_NODELAY` option. |
| `nginx_tcp_nopush` | `true` | `off` | Enable tcp_nopush. |
| `nginx_server_tokens` | `undefined` | `on` | Hide Nginx version. |
| `nginx_types_hash_max_size` | `2048` | `1024` | Size of types hash tables. |
| `nginx_types_hash_bucket_size` | `undefined` | `64` | Bucket size for types hash tables. |
| `nginx_server_names_hash_max_size` | `undefined` | `512` | Max size of the server names hash table. |
| `nginx_server_names_hash_bucket_size` | `undefined` | `32\|64\|128` | Bucket size for server names hash tables. |
| `nginx_server_name_in_redirect` | `undefined` | `off` | Use primary server name in redirects. |
| `nginx_variables_hash_max_size` | `undefined` | `1024` | Max size of the variables hash table. |
| `nginx_variables_hash_bucket_size`| `undefined` | `64` | Bucket size for the variables hash table. |
| `nginx_map_hash_max_size` | `undefined` | `2048` | Max size of the map variables hash table. |
| `nginx_map_hash_bucket_size` | `undefined` | `32\|64\|128` | Bucket size for the map variables hash table. |
| `nginx_default_type` | `application/octet-stream` | `text/plain` | Overrides the default MIME type used for unknown content types. |
| `nginx_keepalive_timeout` | omitted in Debian layout, `65` in upstream layout | `75s` | Keepalive timeout in the `http` block. |
| `nginx_use` | `undefined` | platform dependent | Explicitly selects the event method for the `events` block. |

#### SSL
Official Nginx documentation for the modules configured by this section:
* [HTTP SSL module](https://nginx.org/en/docs/http/ngx_http_ssl_module.html)

| Variable | Role Default | Nginx Default | Description |
|---|---|---|---|
| `nginx_ssl_protocols` | `TLSv1 TLSv1.1 TLSv1.2 TLSv1.3` | `TLSv1 TLSv1.1 TLSv1.2 TLSv1.3` | List of enabled SSL protocols. |
| `nginx_ssl_prefer_server_ciphers`| `true` | `off` | Prefer server ciphers. |
| `nginx_ssl_ciphers` | `undefined` | `HIGH:!aNULL:!MD5` | List of enabled SSL ciphers (can be list or string). |
| `nginx_ssl_session_cache` | `undefined` | `none` | SSL session cache parameters (e.g., `shared:SSL:10m`). |
| `nginx_ssl_dhparam_file` | `undefined` | `-` | Full path to the DH parameter file. |
| `nginx_ssl_dhparam_size` | `2048` | `-` | Size of the generated DH parameter key (if file does not exist). |

#### Gzip
Official Nginx documentation for the modules configured by this section:
* [HTTP Gzip module](https://nginx.org/en/docs/http/ngx_http_gzip_module.html)

| Variable | Role Default | Nginx Default | Description |
|---|---|---|---|
| `nginx_gzip` | `true` | `off` | Enable gzip compression. |
| `nginx_gzip_vary` | `undefined` | `off` | Enable gzip_vary. |
| `nginx_gzip_proxied` | `undefined` | `off` | Enable gzip for proxied requests. |
| `nginx_gzip_comp_level` | `undefined` | `1` | Compression level (1-9). |
| `nginx_gzip_buffers` | `undefined` | `32 4k\|16 8k` | Gzip buffers. |
| `nginx_gzip_http_version`| `undefined` | `1.1` | Minimum HTTP version for gzip. |
| `nginx_gzip_types` | `undefined` | `text/html` | List of MIME types to compress. |
| `nginx_gzip_disable` | `undefined` | `-` | Disables gzipping for matching User-Agents (e.g. `msie6`). |
| `nginx_gzip_min_length` | `undefined` | `20` | Sets the minimum length of a response that will be gzipped. |

#### Logging
Official Nginx documentation: [HTTP Log module](https://nginx.org/en/docs/http/ngx_http_log_module.html)

| Variable | Role Default | Nginx Default | Description |
|---|---|---|---|
| `nginx_access_log` | `/var/log/nginx/access.log` | `logs/access.log` | Path to the default access log. |
| `nginx_log_format` | `undefined` | `main` | List of dictionaries defining custom log formats. Supports `name`, `escape` (e.g., `json`), and `string` (list of format lines). |
| `nginx_logrotate_frequency` | layout specific | `daily` | Frequency of log rotation (e.g., `daily`, `weekly`). |
| `nginx_logrotate_rotate` | layout specific | `14` / `52` | Number of rotated log files to keep. |
| `nginx_log_group` | layout specific | `adm` | Group ownership for log files. |

### Runtime / Filesystem Management

| Variable | Default | Description |
|---|---|---|
| `nginx_working_dirs` | `[]` | Extra directories to create in addition to the layout defaults. Each item may define `path`, `owner`, `group`, `mode`, and `recurse`. |
| `nginx_extra_groups` | `[]` | Extra UNIX groups appended to the runtime user; triggers a service restart. |
| `nginx_cleanup_paths` | `[]` | Arbitrary paths to remove after configuration deployment. Useful for retiring legacy files. |
| `nginx_user` | layout specific | Overrides the runtime user (`www-data` for Debian layout, `nginx` for upstream layout). |
| `nginx_group` | layout specific | Overrides the runtime group. |

#### Proxy Settings
These variables are injected via a generic drop-in. If any of the `nginx_proxy_*` variables listed below are defined, the `proxy.conf` file is automatically generated.

Official Nginx documentation: [HTTP Proxy module](https://nginx.org/en/docs/http/ngx_http_proxy_module.html)

| Variable | Role Default | Nginx Default | Description |
|---|---|---|---|
| `nginx_proxy_buffering` | `undefined` | `on` | Enables or disables buffering of responses from the proxied server. |
| `nginx_proxy_buffer_size` | `undefined` | `4k\|8k` | Sets the size of the buffer used for reading the first part of the response. |
| `nginx_proxy_buffers` | `undefined` | `8 4k\|8k` | Sets the number and size of the buffers used for reading a response. |
| `nginx_proxy_busy_buffers_size`| `undefined` | `8k\|16k` | Limits the total size of buffers that can be busy sending a response. |
| `nginx_proxy_cache_path` | `undefined` | `-` | Sets the path and other parameters of a cache. |
| `nginx_proxy_connect_timeout` | `undefined` | `60s` | Defines a timeout for establishing a connection with a proxied server. |
| `nginx_proxy_headers_hash_bucket_size`| `undefined` | `64` | Sets the bucket size for the proxy headers hash tables. |
| `nginx_proxy_headers_hash_max_size`| `undefined` | `512` | Sets the maximum size of the proxy headers hash tables. |
| `nginx_proxy_max_temp_file_size` | `undefined` | `1024m` | Limits the maximum size of the temporary file for buffering. |
| `nginx_proxy_next_upstream` | `undefined` | `error timeout` | Specifies in which cases a request should be passed to the next server (can be list or string). |
| `nginx_proxy_next_upstream_timeout`| `undefined` | `0` | Limits the time during which a request can be passed to the next server. |
| `nginx_proxy_next_upstream_tries`| `undefined` | `0` | Limits the number of possible tries for passing a request to the next server. |
| `nginx_proxy_read_timeout` | `undefined` | `60s` | Defines a timeout for reading a response from the proxied server. |
| `nginx_proxy_send_timeout` | `undefined` | `60s` | Sets a timeout for transmitting a request to the proxied server. |

#### Real IP
Configures the `ngx_http_realip_module` to change the client address to the one sent in the specified header. You can populate trusted addresses either by referencing the global [IP Sets](#ip-sets-global-dictionaries) or by defining a direct list of IPs.

Official Nginx documentation: [HTTP RealIP module](https://nginx.org/en/docs/http/ngx_http_realip_module.html)

| Variable | Role Default | Nginx Default | Description |
|---|---|---|---|
| `nginx_real_ip_lists` | `undefined` | `-` | List of `nginx_ip_sets` keys to automatically configure `set_real_ip_from` directives. |
| `nginx_real_ip_header` | `undefined` | `X-Real-IP` | Defines the request header used to send the client's real IP address. |
| `nginx_real_ip_recursive`| `undefined` | `off` | Enables recursive search for the client IP address. |
| `nginx_real_ip_set_from`| `undefined` | `-` | A direct list of IP prefixes/CIDRs to define trusted addresses without using the global dictionary (e.g., `['127.0.0.0/8', '::1']`). Useful for simple, host-specific overrides or legacy compatibility. |

### Server Configuration Model

Server files are managed through `nginx_servers`. The role combines built-in defaults with your entries, deduplicates them by `name`, and lets the last definition win. Layout defaults also inject a `default` server automatically.

Each item in `nginx_servers` can use the following fields:

| Field | Description |
|---|---|
| `name` | Logical name of the server entry. Also used as the default template and filename base. |
| `template` | Template path relative to `roles/nginx/templates/` without the `.j2` suffix. |
| `filename` | Output filename override. Defaults to `name`. |
| `state` | `present` or `absent`. When absent, both config file and symlink are removed. |
| `server_dir` | Destination directory for the rendered server config. |
| `server_ext` | Filename suffix for the rendered config (for example, `.conf`). |
| `server_symlink_enable` | Enables symlink creation for this server. Typically used with Debian-style layouts. |
| `server_symlink_dir` | Directory where the symlink is created. |
| `server_symlink_ext` | Suffix for the symlink filename. |
| `symlink_prefix` | Prefix added to the symlink name, useful for deterministic ordering. |

Global overrides for the same path mechanics are also supported:
- `nginx_server_dir`
- `nginx_server_ext`
- `nginx_server_symlink_enable`
- `nginx_server_symlink_dir`
- `nginx_server_symlink_ext`
- `nginx_server_symlink_prefix`

Built-in server templates:
- `layouts/debian/default`
- `layouts/upstream/default`
- `servers/status`

### Bundled Site Templates

The role ships with a small set of bundled templates intended as safe building blocks rather than full application vhosts.

#### `default`

`layouts/debian/default` and `layouts/upstream/default` provide the stock catch-all server for the active layout. The role injects one `default` entry automatically, so you normally get it without defining anything in `nginx_servers`.

Use cases:
- keep a predictable fallback vhost after first install
- explicitly control ordering via `symlink_prefix`
- replace the built-in default with a definition that matches your overridden layout paths
- remove the default altogether by declaring the same `name` with `state: absent`

For structured removals of managed vhosts, you can declare the same `name` with `state: absent`. For ad-hoc cleanup of legacy or unstructured files, use `nginx_cleanup_paths`: the role processes this list at the end and removes each path explicitly.

This is especially relevant during repository or layout migrations: package-provided defaults and old hand-made files may survive outside the role's managed server list. In that case, redefine or disable the managed `default` entry as needed, and use `nginx_cleanup_paths` as the final garbage collector for leftovers that do not map cleanly to `nginx_servers`.

Examples:

```yaml
nginx_servers:
  - name: "default"
    symlink_prefix: "000_"
    template: "layouts/upstream/default"
```

```yaml
nginx_servers:
  - name: "default"
    state: "absent"
```

#### `status`

`servers/status` renders a simple `stub_status` server. By default it:
- listens on `80` and `[::]:80`
- uses `localhost` as `server_name`
- exposes `/`
- allows only loopback clients unless you override access rules

Supported template inputs include:
- `listen`
- `server_name`
- `access_log`
- `root`
- `access`
- `locations`

Access rules are rendered exactly in the order you write them. This means you can intentionally mix `allow` and `deny`: for example, deny one specific host first, then allow its wider subnet, and still finish with a default `deny all`. Think of it as a plain ordered ACL list, not as a smart merge.

Examples:

```yaml
nginx_servers:
  - name: "status"
    template: "servers/status"
    filename: "status"
    symlink_prefix: "010_"
    listen:
      - "127.0.0.1:8080"
      - "[::1]:8080"
```

```yaml
nginx_servers:
  - name: "app-status"
    template: "servers/status"
    listen: "127.0.0.1:81"
    server_name: "status.example.internal"
    access_log: "off"
    root: "/var/www/status.example.internal"
    access:
      - allow: "127.0.0.1"
      - deny: "all"
    locations:
      - name: "/nginx-status"
```

```yaml
nginx_servers:
  - name: "multi-status"
    template: "servers/status"
    listen: "8080"
    locations:
      - name: "/status-local"
        access:
          - allow: "127.0.0.1"
          - deny: "all"
      - name: "/status-office"
        access:
          - allow: "192.0.2.0/24"
          - deny: "all"
```

### Migration / Override Example

It is possible to take packages from `nginx_org_mainline` but override the role into a Debian-like server layout. This is valid, but it is exactly the kind of configuration that should be reviewed line by line.

The important detail is the built-in `default` server: once you override `nginx_server_dir` and symlink behavior, either redefine `default` so it lands in the same path scheme as the rest of your sites, or remove it explicitly.

Example with a matching explicit `default` definition:

```yaml
nginx_repositories:
  nginx_org_mainline:
    enabled: true

nginx_http_includes:
  - "/etc/nginx/sites-enabled/*"

nginx_server_dir: "/etc/nginx/sites-available"
nginx_server_ext: ""
nginx_server_symlink_enable: true
nginx_server_symlink_dir: "/etc/nginx/sites-enabled"
nginx_server_symlink_prefix: "050_"
nginx_server_symlink_ext: ""

nginx_servers:
  - name: "default"
    template: "layouts/upstream/default"
    server_dir: "/etc/nginx/sites-available"
    server_ext: ""
    server_symlink_enable: true
    server_symlink_dir: "/etc/nginx/sites-enabled"
    server_symlink_prefix: ""
    server_symlink_ext: ""
```

Alternative if you do not want the bundled fallback at all:

```yaml
nginx_repositories:
  nginx_org_mainline:
    enabled: true

nginx_http_includes:
  - "/etc/nginx/sites-enabled/*"

nginx_server_dir: "/etc/nginx/sites-available"
nginx_server_ext: ""
nginx_server_symlink_enable: true
nginx_server_symlink_dir: "/etc/nginx/sites-enabled"
nginx_server_symlink_prefix: "050_"
nginx_server_symlink_ext: ""

nginx_servers:
  - name: "default"
    state: "absent"
```

### Includes and Generated Drop-ins

| Variable | Default | Description |
|---|---|---|
| `nginx_http_includes` | `[]` | Extra `include` directives appended to the layout defaults inside the `http` block. |

Drop-ins are generated automatically in `/etc/nginx/conf.d/`:
- `proxy.conf` when any `nginx_proxy_*` variable is defined
- `gzip.conf` when any `nginx_gzip_*` variable is defined
- `realip.conf` when any `nginx_real_ip_*` variable is defined

### Handlers and Validation

Every configuration-changing task notifies `Reload nginx`. The handler flow is:
- run `nginx -t` using the active layout binary path
- attempt a service reload
- fall back to restart if reload fails

`Restart nginx` also validates configuration first. Repository changes trigger an immediate APT cache refresh via a dedicated handler flush.

## Example

```yaml
- name: Setup Nginx
  hosts: webservers
  roles:
    - name: habr.linuxhost.nginx
      vars:
        nginx_repositories:
          nginx_org:
            enabled: true

        nginx_ip_sets:
          cdn:
            - net: "203.0.113.0/24"
            - net: "2001:db8::/32"
          office_vpn:
            - net: "192.0.2.0/24"

        nginx_real_ip_lists:
          - cdn
          - office_vpn
        nginx_real_ip_header: "X-Forwarded-For"
        nginx_real_ip_recursive: true

        nginx_proxy_read_timeout: "30s"
        nginx_proxy_send_timeout: "30s"

        nginx_ssl_dhparam_file: "/etc/nginx/ssl/dhparam.pem"

        nginx_servers:
          - name: "status"
            template: "servers/status"
            filename: "status"
            symlink_prefix: "010_"
            listen:
              - "127.0.0.1:8080"
              - "[::1]:8080"
```
