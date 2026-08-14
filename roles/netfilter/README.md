# Netfilter Ansible Role

This role installs and configures `netfilter-persistent` along with its plugins
(`iptables-persistent` and `ipset-persistent`) to manage static firewall rules
and IP sets across reboots on Debian/Ubuntu systems.

The role provides a **declarative, idempotent baseline setup** for server
firewalls using raw iptables/ipset syntax. High-level abstractions (like UFW
or firewalld) and dynamic rule management are intentionally out of scope.

---

## What this role does

- Detects supported OS releases before execution
- Installs `netfilter-persistent`, `iptables-persistent`, and `ipset-persistent` packages
- Detects an installed UFW package and requires explicit permission before
  removing it in favor of `netfilter-persistent`
- Generates `/etc/iptables/ipsets` for declarative IP set management
- Generates `/etc/iptables/rules.v4` and `/etc/iptables/rules.v6`
- Restarts the `netfilter-persistent` service to apply changes upon configuration updates

---

## Upstream configuration reference

This role maps Ansible variables directly into the native formats expected by
`iptables-save`/`iptables-restore` and `ipset save`/`ipset restore`.

Authoritative references:
- `man 8 iptables`
- `man 8 ipset`

The sections below describe **how this role implements** specific parts of that
configuration.

---

## IPSet configuration

When `netfilter_use_ipset` is set to `true`, the role manages sets via the
`netfilter_ipsets` list.

Behavior:
- Sets are defined with their `name`, `type`, and `family` (e.g., `hash:net`, `inet` or `inet6`).
- Default sizing parameters (`hashsize`, `maxelem`) can be configured globally
  or per-set.
- Static IP lists or subnets can be populated via the `addrs` list.

Relevant variables:
- `netfilter_use_ipset`
- `netfilter_ipsets`
- `netfilter_ipset_hashsize`
- `netfilter_ipset_maxelem`
- `netfilter_ipset_type`
- `netfilter_ipset_family`

---

## IPTables configuration

When `netfilter_use_iptables` is set to `true`, the role processes rules mapped
in the `netfilter_iptables` list.

Behavior:
- Tables (e.g., `filter`, `nat`, `mangle`, `raw`) are segregated by IP version (`ip_ver: 4` or `ip_ver: 6`).
- Chains (e.g., `INPUT`, `FORWARD`, `OUTPUT`) are defined with their default `policy` (e.g., `ACCEPT` or `DROP`).
- Custom user-defined chains are supported and safely initialized by setting `user_defined: true`.
- Raw rules are appended sequentially exactly as defined in the `rules` list (without the `-A <chain>` prefix, which the template handles).

Relevant variables:
- `netfilter_use_iptables`
- `netfilter_iptables`

---

## UFW replacement

The `ufw` package conflicts with the persistent netfilter packages on supported
Ubuntu releases. The role checks installed package facts before changing the
firewall stack; it does not inspect UFW configuration or execute the `ufw`
command.

If UFW is installed, the role fails by default. Set
`netfilter_replace_ufw: true` to explicitly allow the role to remove the `ufw`
package before installing `netfilter-persistent` and its enabled plugins.

This is a package ownership handoff only. The role does not translate or
preserve UFW rules.

---

## Configuration variables

This role exposes configuration via variables prefixed with `netfilter_`.

The **complete and authoritative list** of available variables and defaults
can be found in:

```
roles/netfilter/defaults/main.yml
```

Only key behaviors are documented in this README.

---

## Limitations and non-goals

This role does **not** implement:

- `nftables` native syntax management (it uses legacy iptables syntax compatibility)
- High-level abstractions like UFW or Firewalld
- Dynamic rule synchronization (e.g., Docker manipulating iptables on the fly or Fail2ban bans)
- Automatic teardown of orphaned rules or sets that were manually added outside of Ansible

These concerns are expected to be handled by local daemons or separate logic.

---

## Requirements

- ansible-core >= 2.18
- Supported platforms: Ubuntu (focal, jammy, noble, resolute)

---

## Example usage

### Example 1: Basic Web Server (IPTables only)

A simple configuration that allows SSH, HTTP, and HTTPS traffic, while dropping everything else by default.

```yaml
# group_vars/webservers.yml
---
netfilter_use_iptables: true
netfilter_use_ipset: false

netfilter_iptables:
  - name: "nat"
    ip_ver: 4
    chains:
      - name: "PREROUTING"
        policy: "ACCEPT"
      - name: "INPUT"
        policy: "ACCEPT"
      - name: "OUTPUT"
        policy: "ACCEPT"
      - name: "POSTROUTING"
        policy: "ACCEPT"

  - name: "mangle"
    ip_ver: 4
    chains:
      - name: "PREROUTING"
        policy: "ACCEPT"
      - name: "INPUT"
        policy: "ACCEPT"
      - name: "FORWARD"
        policy: "ACCEPT"
      - name: "OUTPUT"
        policy: "ACCEPT"
      - name: "POSTROUTING"
        policy: "ACCEPT"

  - name: "filter"
    ip_ver: 4
    chains:
      - name: "INPUT"
        policy: "DROP"
        rules:
          - "-i lo -j ACCEPT"
          - "-d 127.0.0.0/8 -i lo -j REJECT --reject-with icmp-port-unreachable"
          - "-m state --state RELATED,ESTABLISHED -j ACCEPT"
          - "-f -j DROP"
          - "-p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG FIN,SYN,RST,PSH,ACK,URG -j DROP"
          - "-p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -j DROP"
          - "-p icmp -m limit --limit 100/sec --limit-burst 100 -j ACCEPT"
          - "-p tcp -m tcp --dport 22 -j ACCEPT"
          - "-p tcp -m tcp --dport 80 -j ACCEPT"
          - "-p tcp -m tcp --dport 443 -j ACCEPT"
      - name: "FORWARD"
        policy: "DROP"
      - name: "OUTPUT"
        policy: "ACCEPT"

  - name: "filter"
    ip_ver: 6
    chains:
      - name: "INPUT"
        policy: "DROP"
        rules:
          - "-i lo -j ACCEPT"
          - "-d ::1/128 -i lo -j REJECT --reject-with icmp6-port-unreachable"
          - "-s fe80::/10 -j ACCEPT"
          - "-d ff00::/8 -j ACCEPT"
          - "-m set --match-set blacklist.v6 src -j DROP"
          - "-m set --match-set whitelist.v6 src -j ACCEPT"
          - "-m state --state RELATED,ESTABLISHED -j ACCEPT"
          - "-p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG FIN,SYN,RST,PSH,ACK,URG -j DROP"
          - "-p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -j DROP"
          - "-p ipv6-icmp -m limit --limit 100/sec --limit-burst 100 -j ACCEPT"
          - "-p tcp -m tcp --dport 22 -j ACCEPT"
          - "-p tcp -m tcp --dport 80 -j ACCEPT"
          - "-p tcp -m tcp --dport 443 -j ACCEPT"
      - name: "FORWARD"
        policy: "DROP"
      - name: "OUTPUT"
        policy: "ACCEPT"
        rules:
          - "-s fe80::/10 -j ACCEPT"
          - "-d ff00::/8 -j ACCEPT"
```

### Example 2: Transit host with bridged VMs/containers

A configuration that creates IPSets for blacklisted/whitelisted IPs and hosted containers (or VMs). It allows
 specific management traffic to the host and splits container traffic into separate chains by purpose.

 This setup is typical for LXC/LXD bare metal hosts. The example is split into two `group_vars` files: a base
 configuration with empty structures and an environment-specific overlay that populates the
 sets (for example, depending of location).

#### Base group variables with common IPTables rules:

```yaml
# group_vars/container-hosts.yml
---
netfilter_use_iptables: true
netfilter_use_ipset: true

netfilter_ipsets:
  - name: "blacklist.v4"
  - name: "blacklist.v6"
    family: "inet6"
  - name: "whitelist.v4"
  - name: "whitelist.v6"
    family: "inet6"
  - name: "containers.v4"
  - name: "containers.v6"
    family: "inet6"
  - name: "webservers.v4"
  - name: "webservers.v6"
    family: "inet6"
  - name: "nameservers.v4"
  - name: "nameservers.v6"
    family: "inet6"
  - name: "mailservers.v4"
  - name: "mailservers.v6"
    family: "inet6"
  - name: "sshservers.v4"
  - name: "sshservers.v6"
    family: "inet6"
  - name: "openservers.v4"
  - name: "openservers.v6"
    family: "inet6"

netfilter_iptables:
  - name: "raw"
    ip_ver: 4
    chains:
      - name: "PREROUTING"
        policy: "ACCEPT"
      - name: "OUTPUT"
        policy: "ACCEPT"

  - name: "raw"
    ip_ver: 6
    chains:
      - name: "PREROUTING"
        policy: "ACCEPT"
      - name: "OUTPUT"
        policy: "ACCEPT"

  - name: "nat"
    ip_ver: 4
    chains:
      - name: "PREROUTING"
        policy: "ACCEPT"
      - name: "INPUT"
        policy: "ACCEPT"
      - name: "OUTPUT"
        policy: "ACCEPT"
      - name: "POSTROUTING"
        policy: "ACCEPT"

  - name: "mangle"
    ip_ver: 4
    chains:
      - name: "PREROUTING"
        policy: "ACCEPT"
      - name: "INPUT"
        policy: "ACCEPT"
      - name: "FORWARD"
        policy: "ACCEPT"
      - name: "OUTPUT"
        policy: "ACCEPT"
      - name: "POSTROUTING"
        policy: "ACCEPT"

  - name: "mangle"
    ip_ver: 6
    chains:
      - name: "PREROUTING"
        policy: "ACCEPT"
      - name: "INPUT"
        policy: "ACCEPT"
      - name: "FORWARD"
        policy: "ACCEPT"
      - name: "OUTPUT"
        policy: "ACCEPT"
      - name: "POSTROUTING"
        policy: "ACCEPT"

  - name: "filter"
    ip_ver: 4
    chains:
      - name: "INPUT"
        policy: "ACCEPT"
        rules:
          - "-i lo -j ACCEPT"
          - "-d 127.0.0.0/8 -i lo -j REJECT --reject-with icmp-port-unreachable"
          - "-m set --match-set blacklist.v4 src -j DROP"
          - "-m set --match-set whitelist.v4 src -j ACCEPT"
          - "-m state --state RELATED,ESTABLISHED -j ACCEPT"
          - "-f -j DROP"
          - "-p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG FIN,SYN,RST,PSH,ACK,URG -j DROP"
          - "-p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -j DROP"
          - "-p icmp -m limit --limit 100/s --limit-burst 100 -j ACCEPT"
          - "-p tcp --dport 22 -j ACCEPT"
          - "-j DROP"
      - name: "FORWARD"
        policy: "ACCEPT"
        rules:
          - "-m set --match-set blacklist.v4 src -j DROP"
          - "-m set --match-set whitelist.v4 src -j ACCEPT"
          - "-m set --match-set containers.v4 src -j ACCEPT"
          - "-m set --match-set containers.v4 dst -j VIRT"
          - "-m state --state RELATED,ESTABLISHED -j ACCEPT"
          - "-j DROP"
      - name: "VIRT"
        user_defined: true
        policy: "ACCEPT"
        rules:
          - "-m state --state RELATED,ESTABLISHED -j ACCEPT"
          - "-f -j DROP"
          - "-p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG FIN,SYN,RST,PSH,ACK,URG -j DROP"
          - "-p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -j DROP"
          - "-p icmp -m limit --limit 100/s --limit-burst 100 -j ACCEPT"
          - "-m set --match-set nameservers.v4 dst -j VIRT-NS"
          - "-m set --match-set mailservers.v4 dst -j VIRT-MX"
          - "-m set --match-set webservers.v4 dst -j VIRT-WS"
          - "-m set --match-set sshservers.v4 dst -j VIRT-SSH"
          - "-m set --match-set openservers.v4 dst -j VIRT-OPEN"
          - "-j DROP"
      - name: "VIRT-NS"
        user_defined: true
        policy: "ACCEPT"
        rules:
          - "-p udp --dport 53 -j ACCEPT"
          - "-p tcp --dport 53 -j ACCEPT"
          - "-j RETURN"
      - name: "VIRT-MX"
        user_defined: true
        policy: "ACCEPT"
        rules:
          - "-p tcp --dport 25 -j ACCEPT"
          - "-p tcp --dport 110 -j ACCEPT"
          - "-p tcp --dport 143 -j ACCEPT"
          - "-p tcp --dport 993 -j ACCEPT"
          - "-p tcp --dport 995 -j ACCEPT"
          - "-p tcp --dport 2000 -j ACCEPT"
          - "-p tcp --dport 4900 -j ACCEPT"
          - "-j RETURN"
      - name: "VIRT-WS"
        user_defined: true
        policy: "ACCEPT"
        rules:
          - "-p tcp --dport 80 -j ACCEPT"
          - "-p tcp --dport 443 -j ACCEPT"
          - "-j RETURN"
      - name: "VIRT-SSH"
        user_defined: true
        policy: "ACCEPT"
        rules:
          - "-p tcp --dport 22 -j ACCEPT"
          - "-j RETURN"
      - name: "VIRT-OPEN"
        user_defined: true
        policy: "ACCEPT"
        rules:
          - "-j ACCEPT"
      - name: "OUTPUT"
        policy: "ACCEPT"

  - name: "filter"
    ip_ver: 6
    chains:
      - name: "INPUT"
        policy: "ACCEPT"
        rules:
          - "-i lo -j ACCEPT"
          - "-d ::1/128 -i lo -j REJECT --reject-with icmp6-port-unreachable"
          - "-s fe80::/10 -j ACCEPT"
          - "-d ff00::/8 -j ACCEPT"
          - "-m set --match-set blacklist.v6 src -j DROP"
          - "-m set --match-set whitelist.v6 src -j ACCEPT"
          - "-m state --state RELATED,ESTABLISHED -j ACCEPT"
          - "-p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG FIN,SYN,RST,PSH,ACK,URG -j DROP"
          - "-p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -j DROP"
          - "-p ipv6-icmp -m limit --limit 100/s --limit-burst 100 -j ACCEPT"
          - "-j DROP"
      - name: "FORWARD"
        policy: "ACCEPT"
        rules:
          - "-s fe80::/10 -j ACCEPT"
          - "-d ff00::/8 -j ACCEPT"
          - "-m set --match-set blacklist.v6 src -j DROP"
          - "-m set --match-set whitelist.v6 src -j ACCEPT"
          - "-m set --match-set containers.v6 src -j ACCEPT"
          - "-m set --match-set containers.v6 dst -j VIRT"
          - "-m state --state RELATED,ESTABLISHED -j ACCEPT"
          - "-j DROP"
      - name: "VIRT"
        user_defined: true
        policy: "ACCEPT"
        rules:
          - "-m state --state RELATED,ESTABLISHED -j ACCEPT"
          - "-p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG FIN,SYN,RST,PSH,ACK,URG -j DROP"
          - "-p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -j DROP"
          - "-p ipv6-icmp -m limit --limit 100/s --limit-burst 100 -j ACCEPT"
          - "-m set --match-set nameservers.v6 dst -j VIRT-NS"
          - "-m set --match-set mailservers.v6 dst -j VIRT-MX"
          - "-m set --match-set webservers.v6 dst -j VIRT-WS"
          - "-m set --match-set sshservers.v6 dst -j VIRT-SSH"
          - "-m set --match-set openservers.v6 dst -j VIRT-OPEN"
          - "-j DROP"
      - name: "VIRT-NS"
        user_defined: true
        policy: "ACCEPT"
        rules:
          - "-p udp --dport 53 -j ACCEPT"
          - "-p tcp --dport 53 -j ACCEPT"
          - "-j RETURN"
      - name: "VIRT-MX"
        user_defined: true
        policy: "ACCEPT"
        rules:
          - "-p tcp --dport 25 -j ACCEPT"
          - "-p tcp --dport 110 -j ACCEPT"
          - "-p tcp --dport 143 -j ACCEPT"
          - "-p tcp --dport 993 -j ACCEPT"
          - "-p tcp --dport 995 -j ACCEPT"
          - "-p tcp --dport 2000 -j ACCEPT"
          - "-p tcp --dport 4900 -j ACCEPT"
          - "-j RETURN"
      - name: "VIRT-WS"
        user_defined: true
        policy: "ACCEPT"
        rules:
          - "-p tcp --dport 80 -j ACCEPT"
          - "-p tcp --dport 443 -j ACCEPT"
          - "-j RETURN"
      - name: "VIRT-SSH"
        user_defined: true
        policy: "ACCEPT"
        rules:
          - "-p tcp --dport 22 -j ACCEPT"
          - "-j RETURN"
      - name: "VIRT-OPEN"
        user_defined: true
        policy: "ACCEPT"
        rules:
          - "-j ACCEPT"
      - name: "OUTPUT"
        policy: "ACCEPT"
        rules:
          - "-s fe80::/10 -j ACCEPT"
          - "-d ff00::/8 -j ACCEPT"
```

#### Location-specific group variables overriding the base IPSets:

```yaml
# group_vars/uthopia-hosts.yml
---
netfilter_ipsets:
  - name: "blacklist.v4"
  - name: "blacklist.v6"
    family: "inet6"

  - name: "whitelist.v4"
    addrs:
      - "10.0.0.0/8"
      - "192.168.0.0/24"

  - name: "whitelist.v6"
    family: "inet6"
    addrs:
      - "2001:db8:1::/48"

  - name: "containers.v4"
    addrs:
      - "10.10.0.0/24"
      - "198.51.100.0/27"
      - "203.0.113.0/27"

  - name: "containers.v6"
    family: "inet6"
    addrs:
      - "2001:db8:1::/64"

  - name: "webservers.v4"
    addrs:
      - "10.10.0.0/24"
      - "198.51.100.0/27"
      - "203.0.113.0/27"

  - name: "webservers.v6"
    family: "inet6"
    addrs:
      - "2001:db8:1::/64"

  - name: "nameservers.v4"
    addrs:
      - "198.51.100.100"

  - name: "nameservers.v6"
    family: "inet6"
    addrs:
      - "2001:db8:1:100::100"

  - name: "mailservers.v4"
    addrs:
      - "203.0.113.0/27"

  - name: "mailservers.v6"
    family: "inet6"
    addrs:
      - "2001:db8:1:25::/64"

  - name: "sshservers.v4"
    addrs:
      - "203.0.113.164"

  - name: "sshservers.v6"
    family: "inet6"
    addrs:
      - "2001:db8:1:1002::164"

  - name: "openservers.v4"
    addrs:
      - "203.0.113.165"
      - "203.0.113.166"
      - "203.0.113.167"

  - name: "openservers.v6"
    family: "inet6"
    addrs:
      - "2001:db8:1:1002::165"
      - "2001:db8:1:1002::166"
      - "2001:db8:1:1002::167"
```

### Playbook execution

```yaml
- name: Configure Netfilter
  hosts: netfilter_hosts
  become: true
  roles:
    - habr.linuxhost.netfilter
```
