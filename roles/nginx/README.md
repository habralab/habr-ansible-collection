# Role: Nginx

Installs and configures Nginx using a layout-driven approach that supports the Ubuntu distribution packages, Ondrej PPA, and the official Nginx.org stable or mainline repositories.

The selected repository affects not only package origin and update cadence, but also the filesystem layout the role manages. Ubuntu and Ondrej use the familiar Debian-style structure with `sites-available` / `sites-enabled`, while Nginx.org uses the upstream-style layout centered around `conf.d`. In practice, this changes the default package set, runtime user, generated include paths, logrotate retention, and whether server configs are enabled through symlinks or rendered directly into the active directory.

## Scope

- Selects one active package source and automatically switches the filesystem layout between Debian-style (`sites-available` / `sites-enabled`) and upstream-style (`conf.d` only).
- Optionally manages APT repositories through the internal `apt_repo` helper role.
- Installs and removes packages, deploys the base `nginx.conf` and companion files, and validates configuration before reload/restart.
- Creates optional global HTTP drop-ins for proxy and Real IP settings based on the variables you define.
- Manages server configs from a declarative `nginx_servers` list, including optional symlinks for Debian-style layouts.
- Prepares runtime directories, logrotate configuration, DH parameters, runtime group membership, and cleanup of obsolete paths.

**Out of Scope:** This role does not ship application-specific website templates. It does ship a small set of bundled infrastructure-oriented templates, including the layout defaults, `servers/status`, and the declarative `servers/vhost` model. Highly application-specific sites should still be expressed either through your own Jinja templates or through the supported `servers/vhost` data model where it is sufficient.

**Current Model Boundary:** The declarative API in this role currently targets the nginx HTTP layer. In practice this means `nginx_servers`, `nginx_auth`, `nginx_geos`, `nginx_maps`, `nginx_proxy_*`, `nginx_real_ip_*`, and server-level location preset sugars are HTTP-oriented abstractions. Stream/TCP/UDP proxying is intentionally outside the current role model and should be introduced later as a separate parallel namespace if it becomes a real requirement.

## Reading Guide

If you are opening this README from scratch, this is probably not a one-coffee read. A practical reading order is:

- [Variables](#variables)
- [Repository Selection and Layouts](#repository-selection-and-layouts)
- [`nginx_servers`](#server-management)
- [`servers/vhost`](#vhost)
- feature-specific sections only when you actually need them

If you are extending the role rather than using it, continue with `DEVELOPMENT.md` after the public contract in this README.

## Variables

### Core Role Variables
| Variable | Default | Description |
|---|---|---|
| `nginx_repo_manage` | `true` | Whether the role should manage APT repositories. |
| `nginx_packages` | `[]` | Explicit list of packages to install. Overrides layout defaults. |
| `nginx_remove_packages` | `[]` | List of packages to purge before installation. |
| `nginx_repositories` | `{}` | Dictionary to configure/enable repositories (see overrides). |
| `nginx_only_servers` | `[]` | Optional rollout filter for managed server entries. Intended primarily for CLI use with `-e`. Accepts a single shell-style pattern, a comma-separated string, or a list of patterns. Matches against server `name`, `filename`, and `server_name`. Only `*` wildcard is supported. |

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
| `nginx_log_format` | `undefined` | `main` | List of dictionaries defining custom log formats. Supports `name`, `escape` (e.g., `json`), and `string` (list of format lines). When set, this list replaces the layout-provided log format declarations; include `main` explicitly if you still want it. |
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

### Managed Includes
The role can render reusable include companions into `/etc/nginx/includes`. These files are meant to be referenced from server templates such as `servers/vhost`, and the directory is intended to grow over time beyond auth-specific helpers.

Current managed include families:
- `auth.<name>.include`: reusable auth/access bundles
- `auth.<name>.passwd`: passwd companions for bundles that enable HTTP Basic auth

General behavior:
- Include filenames are derived from the logical object `name`.
- Include companions are rendered only for managed objects declared in role variables.
- Optional companion files are created only when the corresponding feature is enabled by the data model.
- Managed include files are removed when the owning object is switched to `state: absent`.

### Auth Includes
Managed auth include/passwd companions for reuse across vhosts and locations. This layer combines access control and optional HTTP Basic authentication under a single named auth bundle.

Official Nginx documentation for the directives configured by this section:
* [HTTP Access module](https://nginx.org/en/docs/http/ngx_http_access_module.html)
* [HTTP Auth Basic module](https://nginx.org/en/docs/http/ngx_http_auth_basic_module.html)
* [HTTP Core `satisfy` directive](https://nginx.org/en/docs/http/ngx_http_core_module.html#satisfy)

| Variable | Default | Description |
|---|---|---|
| `nginx_auth` | `[]` | List of managed auth bundles. Each item may define `name`, `satisfy`, `access`, `basic`, and optional `state`. |
| `nginx_auth_passwd_list` | `[]` | Shared passwd dictionaries referenced from `nginx_auth[*].basic.passwd_lists`. Each item uses `name` and `passwd` where entries contain `user` and `hash`. |

Rendered files:
- `/etc/nginx/includes/auth.<name>.include`
- `/etc/nginx/includes/auth.<name>.passwd` when `basic.passwd_lists` is defined and non-empty

Notes:
- Files are rendered into `/etc/nginx/includes`, which is intended for managed include companions beyond auth as the role grows.
- `nginx_auth[*].access.ip_sets` references keys from `nginx_ip_sets` and renders ordered ACL rules for every prefix in those sets.
- Every `ip_sets` item uses `name` and optional `action`; `action` defaults to `allow`.
- `nginx_auth[*].access.default_action` renders the terminal access rule and defaults to `deny`.
- HTTP Basic authentication is enabled only when `basic.banner` and `basic.passwd_lists` are both defined.
- User entries in `nginx_auth_passwd_list` use `hash`, not `pass`. This is an intentional breaking change for the new managed path.
- Set `state: absent` on a `nginx_auth` item to remove its generated include and optional passwd companion.

`nginx_auth` item fields:

| Field | Required | Description |
|---|---|---|
| `name` | yes | Logical auth bundle name. Also used in rendered filenames `auth.<name>.include` and `auth.<name>.passwd`. |
| `satisfy` | no | Value for the nginx `satisfy` directive. Defaults to `any`. |
| `access` | no | Access-control section. Currently supports `ip_sets`. |
| `basic` | no | HTTP Basic auth section. Controls `auth_basic` and the optional passwd companion file. |
| `state` | no | `present` or `absent`. Defaults to `present`. |

`nginx_auth[*].access` item fields:

| Field | Required | Description |
|---|---|---|
| `ip_sets` | no | Ordered list of references to `nginx_ip_sets`. Each item defines `name` and optional `action`. |
| `default_action` | no | Terminal action rendered as the final access rule. Supported values are `allow` and `deny`. Defaults to `deny`. |

`nginx_auth[*].access.ip_sets[]` item fields:

| Field | Required | Description |
|---|---|---|
| `name` | yes | Key from `nginx_ip_sets` to expand into one or more address rules. |
| `action` | no | ACL action for every entry in the referenced set. Supported values are `allow` and `deny`. Defaults to `allow`. |

`nginx_auth[*].basic` item fields:

| Field | Required | Description |
|---|---|---|
| `banner` | yes | Value for `auth_basic`, shown by the client as the auth realm/prompt. |
| `passwd_lists` | yes | Ordered list of shared passwd-list names from `nginx_auth_passwd_list`. |

`nginx_auth_passwd_list` item fields:

| Field | Required | Description |
|---|---|---|
| `name` | yes | Shared passwd-list name referenced from `nginx_auth[*].basic.passwd_lists`. |
| `passwd` | yes | List of htpasswd-compatible user entries. |

`nginx_auth_passwd_list[*].passwd[]` item fields:

| Field | Required | Description |
|---|---|---|
| `user` | yes | Login name written to the passwd file. |
| `hash` | yes | Precomputed htpasswd-compatible hash. Plaintext passwords are intentionally not supported by this role path. |

Minimal example:

```yaml
nginx_auth:
  - name: "service_admin"
    access:
      ip_sets:
        - name: "localhost"
        - name: "private"
        - name: "trusted_networks"
    basic:
      banner: "Password required"
      passwd_lists:
        - "service_admin"

nginx_auth_passwd_list:
  - name: "service_admin"
    passwd:
      - user: "admin"
        hash: "<HTPASSWD_HASH_PLACEHOLDER>"
```

Allow-by-default example:

```yaml
nginx_auth:
  - name: "blacklist_only"
    access:
      default_action: "allow"
      ip_sets:
        - name: "blocked_hosts"
          action: "deny"
```

Access-only example:

```yaml
nginx_auth:
  - name: "restricted_network"
    satisfy: "all"
    access:
      default_action: "deny"
      ip_sets:
        - name: "blocked_hosts"
          action: "deny"
        - name: "trusted_networks"
```

Access evaluation notes:
- Rules are rendered in the order you define them.
- The example above first denies explicitly blocked hosts and then allows the wider trusted prefix set.
- When `access` is defined, the helper always appends a terminal rule based on `default_action`.
- The default terminal rule is `deny all;`.
- Set `default_action: "allow"` for blacklist-style configurations where all unmatched clients should pass the access layer.

Hash generation hints:

```bash
openssl passwd -apr1 'secret-password'
openssl passwd -6 'secret-password'
openssl passwd -5 'secret-password'
```

Notes on hash formats:
- `-apr1` produces Apache MD5 hashes and is widely accepted in `.htpasswd`-style workflows.
- `-6` produces SHA-512 crypt hashes.
- `-5` produces SHA-256 crypt hashes.
- Availability of algorithms depends on the target system OpenSSL/libcrypt stack, so generate hashes on a platform compatible with your fleet.

### Maps
Managed `map` blocks for the `http` context.

Official Nginx documentation: [HTTP Map module](https://nginx.org/en/docs/http/ngx_http_map_module.html)

| Variable | Default | Description |
|---|---|---|
| `nginx_maps` | `[]` | List of managed map definitions. Each item may define `name`, `source`, `target`, `entries`, `default`, `hostnames`, `volatile`, and optional `state`. |

Rendered files:
- `/etc/nginx/conf.d/maps.conf` when `nginx_maps` is non-empty

`nginx_maps` item fields:

| Field | Required | Description |
|---|---|---|
| `name` | no | Optional logical identifier used only for human readability inside the data model. |
| `source` | yes | First argument of the nginx `map` directive, usually a source variable such as `$host` or `$request_uri`. |
| `target` | yes | Target variable set by the map, including the leading `$`. |
| `entries` | no | Ordered list of map entries. Each item defines `match` and `value`. |
| `default` | no | `default` clause for the map. Rendered as a single-quoted string. |
| `hostnames` | no | Enables the `hostnames;` flag for hostname masks. |
| `volatile` | no | Enables the `volatile;` flag. |
| `state` | no | `present` or `absent`. Defaults to `present`. |

`nginx_maps[*].entries[]` item fields:

| Field | Required | Description |
|---|---|---|
| `match` | yes | Match expression for the map entry. Rendered as a single-quoted string, which is safer for regex-heavy patterns. |
| `value` | yes | Result assigned when the entry matches. Rendered as a single-quoted string. |

Naming notes:
- `source` and `target` are clearer than legacy names like `string` and `variable`.
- `entries` is clearer than legacy `set`, because these items are ordered map entries, not arbitrary sets.
- `match` and `value` are clearer than `condition` and `result` for day-to-day maintenance.
- `name` remains available as a logical label, but with the singleton drop-in approach it no longer controls filenames.
- The current renderer uses single quotes for `default`, `match`, and `value`, following the safer legacy behavior for complex regex maps.

Minimal example:

```yaml
nginx_maps:
  - name: "forwarded_proto"
    source: "$http_x_forwarded_proto"
    target: "$request_scheme"
    default: "$scheme"
    entries:
      - match: "http"
        value: "http"
      - match: "https"
        value: "https"
```

Hostname example:

```yaml
nginx_maps:
  - name: "canonical_host"
    source: "$host"
    target: "$is_primary_host"
    hostnames: true
    default: "0"
    entries:
      - match: "example.org"
        value: "1"
      - match: "*.example.org"
        value: "1"
```

Regex-heavy example:

```yaml
nginx_maps:
  - name: "detected_device"
    source: "$http_user_agent"
    target: "$detected_device"
    default: "desktop"
    entries:
      - match: '~*\b(sch-i[89]0\d|shw-m380s|sm-[pt]\w{2,4}|gt-[pn]\d{2,4}|sgh-t8[56]9|nexus 10)'
        value: "tablet"
      - match: '~*\b((?:s[cgp]h|gt|sm)-\w+|galaxy nexus)'
        value: "mobile"
```

Regex quoting note:
- In YAML, regex-heavy `match` strings should usually be wrapped in single quotes so backslashes and `{m,n}` fragments survive parsing unchanged.
- The role renderer also wraps `default`, `match`, and `value` in single quotes inside the generated nginx config, following the safer legacy behavior for complex map patterns.

### Geos
Managed `geo` blocks for the `http` context.

Official Nginx documentation: [HTTP Geo module](https://nginx.org/en/docs/http/ngx_http_geo_module.html)

| Variable | Default | Description |
|---|---|---|
| `nginx_geos` | `[]` | List of managed geo definitions. Each item may define `name`, `source`, `target`, `entries`, `default`, `ranges`, `proxy`, `proxy_recursive`, `includes`, `deletes`, `volatile`, and optional `state`. |

Rendered files:
- `/etc/nginx/conf.d/geos.conf` when `nginx_geos` is non-empty

`nginx_geos` item fields:

| Field | Required | Description |
|---|---|---|
| `name` | no | Optional logical identifier used only inside the data model. |
| `source` | no | Optional source variable for the two-argument form `geo $source $target`. When omitted, nginx uses the default client address source. |
| `target` | yes | Target variable set by the geo block, including the leading `$`. |
| `entries` | no | Ordered list of geo entries. Each item defines `match` and `value`. |
| `default` | no | `default` clause for the geo block. |
| `ranges` | no | Enables the `ranges;` flag. |
| `proxy` | no | One network or a list of networks rendered as `proxy ...;` directives. |
| `proxy_recursive` | no | Enables `proxy_recursive on|off;`. |
| `includes` | no | One or more include files rendered as `include ...;`. |
| `deletes` | no | One or more deleted networks rendered as `delete ...;`. |
| `volatile` | no | Enables the `volatile;` flag. |
| `state` | no | `present` or `absent`. Defaults to `present`. |

`nginx_geos[*].entries[]` item fields:

| Field | Required | Description |
|---|---|---|
| `match` | yes | CIDR, range, or other valid geo match expression. |
| `value` | yes | Result assigned when the entry matches. |

Minimal example:

```yaml
nginx_geos:
  - name: "maintenance_prefixes"
    target: "$maintenance_prefixes"
    default: "0"
    entries:
      - match: "127.0.0.0/8"
        value: "1"
      - match: "10.0.0.0/8"
        value: "1"
```

### Server Location Presets
Reusable location presets for `servers/vhost`.

These variables let you define shared location blocks once, enable them globally by default, and then disable or override them per server without duplicating full location objects.

| Variable | Default | Description |
|---|---|---|
| `nginx_server_location_presets` | `{}` | Registry of named preset definitions. Each item may be a location object directly or an object with a nested `location` field. |
| `nginx_server_location_preset_defaults` | `{}` | Global activation and override defaults for preset keys. Each item may define `enabled` and optional nested `location` overrides. |

Preset activation happens only inside `servers/vhost`. Explicit `locations` defined on a server remain authoritative and win over preset-derived locations with the same `name`.

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

For iterative rollouts you can narrow the managed subset with `nginx_only_servers`.

Rules:
- leave it unset or empty to manage all server entries
- prefer CLI use through `-e` during iterative rollout
- pass either a single string or a comma-separated string such as `app.example.com,api-*`
- YAML or JSON lists are still accepted as a compatibility fallback
- patterns use shell-style `*`, not raw regex
- matching is performed against each entry's `name`, `filename`, and `server_name`
- absent-state entries are filtered through the same mechanism, so a narrow rollout will not remove unrelated server files

Inline examples:

```bash
ansible-playbook -i inventory playbook.yml -l edge-0.example.net -e 'nginx_only_servers=app.example.com'
```

```bash
ansible-playbook -i inventory playbook.yml -l edge-0.example.net -e 'nginx_only_servers=app.example.com,api-*'
```

Structured fallback example:

```yaml
nginx_only_servers:
  - "app.example.com"
  - "api-*"
```

Built-in server templates:
- `layouts/debian/default`
- `layouts/upstream/default`
- `servers/status`
- `servers/vhost`

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

#### `vhost`

`servers/vhost` is the role-native declarative HTTP vhost template.

Unlike ad hoc legacy-style templates, `servers/vhost` is driven by an internal rendering model:
- directive registry
- logical block registry
- render context registry (`server`, `location`)
- internal template mode/debug switches used during template development

Current model characteristics:
- HTTP-only. Stream/TCP/UDP is outside the template model.
- `server` and `location` contexts are rendered from internal registries rather than from hardcoded section branches.
- ordering and spacing are part of the template data model
- debug rendering can be enabled internally for template development, but production output is plain nginx syntax

Implications for users:
- common nginx HTTP vhost cases should be expressed through the supported data model
- simple directive support is generally added through the internal registries
- schema-driven or multi-line constructs still require explicit composite renderer support
- `servers/vhost` is the preferred bundled path for role-native HTTP vhost management

Common top-level fields supported by the template include:
- `listen`
- `http2`
- `server_name`
- `server_tokens`
- `access_log`
- `error_log`
- `rewrite_log`
- `ssl_files`
- `auth_list`
- `add_header`
- `client_max_body_size`
- `includes`
- `set`
- `if`
- `fastcgi_pass`
- `fastcgi_params`
- `proxy_*`
- `proxy_cache_valid`
- `rewrite`
- `root`
- `alias`
- `index`
- `try_files`
- `error_page`
- `return`
- `locations`
- `location_presets`
- `geos`
- `upstreams`
- `upstream_members`
- `upstream_pools`
- `upstream_selection`
- `cache_zones`
  These declare named proxy cache zones owned by the server. `proxy_cache` then selects which declared zone to consume.
- `companion_servers`
  These declare additional server blocks owned by the same `servers/vhost` item, for example HTTP-to-HTTPS redirects or wildcard redirect companions.

`companion_servers` should be used for simple sidecar server blocks that belong to the same host identity and do not carry deep standalone routing logic.

Good fits:
- HTTP-to-HTTPS redirects
- `www` or apex redirect companions
- wildcard guard redirects or wildcard catch-all companions
- small hostname guards that make sense only next to the main server

Use with caution:
- small groups of very similar redirect-only domains that are still clearly part of the same main host policy

Not recommended:
- large redirect meshes
- domain packs with their own independent routing policy
- complex redirect logic that would be easier to understand as its own dedicated template or standalone server set

If the companion block stops making sense without the main server, it is probably a good fit. If it starts to look like its own product or redirect policy surface, it probably is not.

The main operational risk of overusing `companion_servers` is that the rendered nginx file becomes a vhost-monolith whose filename no longer clearly explains every hostname it serves. That can make diagnostics and incident response slower, especially when operators inspect `sites-available` or `sites-enabled` and expect filename-to-hostname correspondence to stay obvious.

Location items support the same general model, with the usual nginx context restrictions applied by the directive registry.

Low-level nginx-native directives such as `include` and `set` remain available as first-class fields where the directive registry allows them. They should be used as controlled primitives, not as a substitute for stable higher-level sugar.

`recursive_scheme_header` may be either a boolean or a structured object. When enabled, it injects a namespaced `map` from the incoming proto header to `$<ns>_request_scheme` and wires `proxy_set_header X-Forwarded-Proto` to that derived variable.

Boolean form:

```yaml
recursive_scheme_header: true
```

This is equivalent to:

```yaml
recursive_scheme_header:
  enabled: true
  allowed_values:
    - "http"
    - "https"
  case_sensitive: false
```

Structured form:

```yaml
recursive_scheme_header:
  enabled: true
  allowed_values:
    - "http"
    - "https"
  case_sensitive: false
```

Semantics:
- values outside `allowed_values` fall back to `$scheme`
- `case_sensitive: false` renders case-insensitive `map` matches
- legacy low-level overrides like `recursive_scheme_source`, `recursive_scheme_default`, and `recursive_scheme_entries` remain supported

Selected structured fields have dedicated schema-aware renderers. For example, `proxy_cache_valid` accepts either raw nginx strings or structured entries:

```yaml
proxy_cache_valid:
  - code: 200
    time: "1d"
  - codes: [301, 302, 307, 308]
    time: "1d"
```

Currently supported proxy-related `servers/vhost` fields include: `proxy_http_version`, `proxy_next_upstream`, `proxy_connect_timeout`, `proxy_read_timeout`, `proxy_send_timeout`, `proxy_buffering`, `proxy_request_buffering`, `proxy_buffer_size`, `proxy_buffers`, `proxy_max_temp_file_size`, `proxy_cache`, `proxy_cache_background_update`, `proxy_cache_bypass`, `proxy_cache_key`, `proxy_cache_min_uses`, `proxy_cache_status_header`, `proxy_cache_use_stale`, `proxy_cache_valid`, `proxy_no_cache`, `proxy_pass_header`, `proxy_hide_header`, `proxy_ignore_headers`, `proxy_intercept_errors`, `proxy_set_header`, and `proxy_pass`.

`proxy_cache_status_header` is a template-level convenience field. `true` renders `add_header X-Proxy-Cache-Status $upstream_cache_status;`. You can also override the rendered value explicitly when needed.

`proxy_pass` supports both raw nginx-style strings and a structured consumer form. Current supported forms are:

- raw string, for example `"http://app_backend"`
- `"default"` to use `upstream_default_scheme` plus `upstream_default_target`
- object form with one of:
  - `upstream` / `upstream_name`
  - `pool`
  - `member`
  - `map`
  - `target`
- optional `scheme`

User-defined `upstreams` are materialized into stable generated runtime names and may still be referenced through their short declarative names from `proxy_pass`. Higher-level structures such as `upstream_members`, `upstream_pools`, and `upstream_selection` compile into namespaced upstream or map primitives before rendering.

`geos` is the server-owned companion form of the same HTTP primitive. These blocks are rendered outside `server {}` but are still owned by the same `servers/vhost` item. Server-owned geo targets are materialized into namespaced runtime variables to avoid collisions between vhosts.

`location_presets` is a server-level sugar layer. It does not introduce a new nginx primitive. Instead, it compiles reusable preset definitions into ordinary `locations` before rendering. Preset-derived locations are weaker than explicit `locations` on the same server.

`maintenance` is a server-level sugar layer that compiles into ordinary nginx companion primitives and server directives:
- trigger producers (`geo` or `map`) that yield maintenance bypass variables
- a small generated maintenance switch
- a final `$<ns>_maintenance_active` variable
- server-owned `if`, `error_page`, and `location @maintenance`

Global defaults may be declared in `nginx_server_maintenance`, while per-server overrides live in `maintenance`.

Minimal shape:

```yaml
nginx_server_maintenance:
  file: "/stub_files/503.html"
  triggers:
    - type: "ip_sets"
      ip_sets:
        - "localhost"
        - "private"

nginx_servers:
  - name: "app.example.com"
    template: "servers/vhost"
    maintenance:
      enabled: false
```

Supported trigger types:
- `ip_sets`
- `cookie`
- `map`

Minimal enabled override:

```yaml
maintenance:
  enabled: true
  file: "/stub_files/503.html"
  triggers:
    - type: "ip_sets"
      ip_sets:
        - "localhost"
        - "private"
```

Minimal example:

```yaml
nginx_servers:
  - name: "app.example.com"
    template: "servers/vhost"
    server_name: "app.example.com"
    listen:
      - "443 ssl"
      - "[::]:443 ssl"
    http2: true
    ssl_files:
      - certificate: "ssl/app.example.com/fullchain.pem"
        key: "ssl/app.example.com/privkey.pem"
    access_log:
      - path: "/var/log/nginx/app.example.com_access.log"
        format: "main"
    locations:
      - name: "/"
        proxy_pass: "http://app_backend"
```

Override the built-in `default` server by reusing its `name`:

```yaml
nginx_servers:
  - name: "default"
    template: "layouts/debian/default"
    symlink_prefix: "000_"
```

Reverse proxy with an explicit upstream:

```yaml
nginx_servers:
  - name: "app.example.com"
    template: "servers/vhost"
    server_name: "app.example.com"

    upstreams:
      - name: "app_backend"
        hosts:
          - address: "192.0.2.10:8080"
            remark: "app-0"
          - address: "192.0.2.11:8080"
            remark: "app-1"

    proxy_read_timeout: "20s"
    proxy_send_timeout: "20s"
    proxy_set_header:
      - name: "Host"
        value: "$host"
      - name: "X-Forwarded-For"
        value: "$proxy_add_x_forwarded_for"
      - name: "X-Forwarded-Proto"
        value: "$scheme"

    locations:
      - name: "/"
        proxy_pass: "http://app_backend"
```

Reverse proxy using the structured `proxy_pass` consumer form:

```yaml
nginx_servers:
  - name: "app.example.com"
    template: "servers/vhost"
    server_name: "app.example.com"

    upstream_default_scheme: "http"
    upstream_default_target: "app_backend"

    upstreams:
      - name: "app_backend"
        hosts:
          - address: "192.0.2.10:8080"
            remark: "app-0"

    locations:
      - name: "/"
        proxy_pass: "default"
```

Derived upstream pools and selection maps:

```yaml
nginx_servers:
  - name: "cdn.example.com"
    template: "servers/vhost"
    server_name: "cdn.example.com"

    upstream_members:
      - name: "cdn_local_0"
        address: "198.51.100.10:443"
        remark: "edge-0"
      - name: "cdn_local_1"
        address: "198.51.100.11:443"
        remark: "edge-1"

    upstream_pools:
      - name: "cdn_pool"
        members: ["cdn_local_0", "cdn_local_1"]
        max_fails: 3
        fail_timeout: "10s"

    upstream_selection:
      - name: "cdn_route"
        source:
          cookie: "upstream_route"
        default_target: "cdn_pool"
        selectors:
          - value: "single"
            target: "cdn_local_0"
          - value: "pool"
            target: "cdn_pool"

    locations:
      - name: "/"
        proxy_pass:
          scheme: "https"
          map: "cdn_route"
```

Cached reverse proxy example:

```yaml
nginx_servers:
  - name: "cdn.example.com"
    template: "servers/vhost"
    server_name: "cdn.example.com"

    cache_zones:
      - name: "main"
        keys_zone_size: "64m"
        max_size: "8g"
        inactive: "1h"

    upstreams:
      - name: "cdn_backend"
        hosts:
          - address: "198.51.100.10:443"
            remark: "edge-0"
          - address: "198.51.100.11:443"
            remark: "edge-1"

    proxy_cache: "main"
    proxy_cache_key: "$scheme$request_method$host$uri"
    proxy_cache_min_uses: "1"
    proxy_cache_background_update: true
    proxy_cache_use_stale:
      - "error"
      - "timeout"
      - "invalid_header"
    proxy_cache_valid:
      - "200 1d"
      - "404 5m"
    proxy_cache_status_header: true

    locations:
      - name: "/"
        proxy_pass: "https://cdn_backend"

Companion wildcard redirect example:

```yaml
nginx_servers:
  - name: "assets.example.com"
    template: "servers/vhost"
    server_name: "assets.example.com"

    companion_servers:
      - server_name: "*.assets.example.com"
        listen:
          - "80"
          - "[::]:80"
          - "443 ssl"
          - "[::]:443 ssl"
        ssl_files:
          - certificate: "ssl/assets.example.com/fullchain.pem"
            key: "ssl/assets.example.com/privkey.pem"
        return:
          code: 301
          url: "https://assets.example.com$request_uri"
```
```

SSL handling in `servers/vhost` is currently split into two separate concerns:

- `ssl_files`: authoritative runtime certificate paths rendered into nginx config
- `ssl_provisioning`: future rollout/provisioning hook for certificate deployment workflows

`ssl_files` is authoritative for rendered nginx paths:

```yaml
ssl_files:
  - certificate: "ssl/example/fullchain.pem"
    key: "ssl/example/privkey.pem"
```

`ssl_provisioning` currently exposes only a mock trigger for future rollout logic:

```yaml
ssl_provisioning:
  enabled: true
  name: "example.com"
```

Current contract:
- if `ssl_files` is defined and non-empty, `servers/vhost` renders certificate paths from it
- `ssl_provisioning` does not currently resolve or deploy certificate files automatically
- if `ssl_provisioning.enabled: true` is present, the role only reports the request in tasks for now
- this split is intentional so runtime nginx paths stay stable even if certificate lifecycle logic evolves later

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
- `realip.conf` when any `nginx_real_ip_*` variable is defined

Gzip settings are rendered directly into the layout-specific main `nginx.conf`, not into a generated drop-in.

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
