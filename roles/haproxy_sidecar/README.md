# HAProxy Sidecar (`haproxy_sidecar`)

Provisions dynamic HAProxy configuration fragments for sidecar load-balancing. This role utilizes the `conf.d` directory structure created by the base `haproxy` role.

## Scope

- Deploys discrete configuration files (`50-<service_name>.cfg`) for applications acting as sidecar proxies on the loopback interface.
- Automatically cleans up orphaned configurations if a service is removed from the `haproxy_sidecar_service_bind` list.
- Supports comprehensive health checks, SSL termination (optional), and custom headers.

**Dependencies:** Requires the `habr.linuxhost.haproxy` base role to be applied first.

## Variables

### General
- `haproxy_sidecar_bind_address`: The IP address sidecar services will bind to (default: `127.0.0.1`).
- `haproxy_sidecar_ca_file_path`: Path to the CA certificates file for backend verification.
- `haproxy_sidecar_alpn`: ALPN protocol negotiation string (default: `h2,http/1.1`).

### Services Configuration
- `haproxy_sidecar_services`: A list of dictionaries defining available services. Each item requires a `name`, `bind_port`, and a list of `servers`.
- `haproxy_sidecar_service_bind`: A list of strings (service names). Only services explicitly listed here will be deployed to the host.

### Default Timers
Fallback timings for health checks if not explicitly defined at the service level:
- `haproxy_sidecar_check_fall`: Default fall count (default: `3`).
- `haproxy_sidecar_check_rise`: Default rise count (default: `2`).
- `haproxy_sidecar_check_inter`: Default check interval (default: `2s`).
- `haproxy_sidecar_check_fastinter`: Default fast interval (default: `1s`).
- `haproxy_sidecar_check_downinter`: Default down interval (default: `5s`).

## Example

### 1. Basic HTTP Service (from playbook)
```yaml
- name: Setup Application Sidecars
  hosts: application_servers
  roles:
    - name: habr.linuxhost.haproxy_sidecar
      vars:
        haproxy_sidecar_service_bind:
          - "users_api"
        haproxy_sidecar_services:
          - name: "users_api"
            bind_port: 8081
            mode: "http"
            servers:
              - name: "api_node_1"
                inet_addr: "10.0.0.15"
                inet_port: 80
```

### 2. Advanced Health Checks (Custom Headers & Expected Strings)
```yaml
haproxy_sidecar_services:
  - name: "example_api"
    bind_port: "8081"
    http_host: "custom.host.header"
    http_host_send: true
    http_alpn_send: true
    check_send_method: "GET"
    check_send_uri: "/heartbeat"
    check_send_header:
      - name: "X-Auth-Key"
        string: "secret_token_here"
    check_expect_status:
      - 200
    servers:
      - name: "api_node_1"
        inet_addr: "10.0.0.15"
        inet_port: "80"
```

### 3. Secure Backends (HTTPS/SNI to Upstream)
```yaml
haproxy_sidecar_services:
  - name: "example_secure_api"
    bind_port: "8081"
    http_host: "custom.host.header"
    http_host_send: true
    http_alpn_send: true
    check_send_method: "GET"
    check_send_uri: "/api/v2/liveness?apikey=some_key"
    check_expect_status:
      - 200
    secure_backend: true
    secure_sni_send: true
    servers:
      - name: "api_node_1"
        inet_addr: "10.0.0.15"
        inet_port: "443"
```

### 4. Custom Timers
```yaml
haproxy_sidecar_services:
  - name: "example_api"
    bind_port: "8081"
    http_host: "custom.host.header"
    http_host_send: true
    check_send_method: "GET"
    check_send_uri: "/state"
    check_expect_status:
      - 200
    check_inter: "20s" # Custom check interval override
    servers:
      - name: "api_node_1"
        inet_addr: "10.0.0.15"
        inet_port: "80"
```
