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
| `nginx_multi_accept` | `undefined` | `off` | Accept multiple connections per process. |
| `nginx_sendfile` | `true` | `off` | Enable sendfile. |
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
