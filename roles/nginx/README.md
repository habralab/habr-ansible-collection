# Role: Nginx

Installs and configures Nginx using a layout-driven approach to support different upstream repositories (Ubuntu default, Ondrej PPA, Nginx.org).

## Variables

### Core Role Variables
| Variable | Default | Description |
|---|---|---|
| `nginx_repo_manage` | `true` | Whether the role should manage APT repositories. |
| `nginx_packages` | `[]` | Explicit list of packages to install. Overrides layout defaults. |
| `nginx_remove_packages` | `[]` | List of packages to purge before installation. |
| `nginx_repositories` | `{}` | Dictionary to configure/enable repositories (see overrides). |

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
