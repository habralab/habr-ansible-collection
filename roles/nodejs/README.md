# Node.js

Declaratively provisions system and user-scoped Node.js environments and their
runtime-bound npm packages.

## Scope

- Install NVM for one or more existing users.
- Optionally leave an NVM user's Node.js runtime under external ownership.
- Install and select a requested Node.js version through NVM.
- Install the Node.js packages selected by the Ubuntu archive.
- Configure a NodeSource major channel and install its selected package.
- Converge npm packages through the executable belonging to each managed runtime.
- Expose normalized environment and runtime results for downstream tasks.

## Contract

The role is driven by one non-empty list named `nodejs_environments`. The former
`nodejs_runtimes` input and `nodejs_runtime_results` output are not supported.

Every environment requires:

- `name`: unique result key;
- `scope`: `user` or `system`;
- `state`: currently only `present`;
- `provider`: provider declaration;
- `runtime`: runtime ownership and desired state.

At most one system environment may be declared. User-scoped environment targets
must be unique, but multiple different users may each have an NVM environment.

### NVM provider

NVM requires `scope: user` and an existing `user`:

```yaml
nodejs_environments:
  - name: web-node
    scope: user
    user: web
    state: present
    provider:
      type: nvm
    runtime:
      state: present
      version: "24.19"
      npm_packages:
        - name: corepack
        - name: pm2
```

Optional provider fields:

- `version`: NVM git tag, default `v0.40.4`;
- `profile`: profile path relative to the user home, default `.bashrc`;
- `repo`: NVM git repository URL.

The provider installs its required `ca-certificates`, `curl`, and `git` packages.

An externally managed runtime is explicit:

```yaml
nodejs_environments:
  - name: developer-node
    scope: user
    user: developer
    state: present
    provider:
      type: nvm
    runtime:
      state: unmanaged
```

In this state the role installs and configures NVM but does not inspect, install,
select, or remove Node.js versions. It does not change the NVM `default` alias or
manage npm packages.

### Ubuntu provider

The Ubuntu provider installs `nodejs` from the host's configured Ubuntu APT
policy and adds no external repository:

```yaml
nodejs_environments:
  - name: system-node
    scope: system
    state: present
    provider:
      type: ubuntu
    runtime:
      state: present
```

The distribution selects the version, so `runtime.version` is not accepted. If
`npm_packages` is non-empty, the Ubuntu `npm` package is installed as well.

Selecting this provider removes repository and preference artifacts managed by
this role for NodeSource. It cannot guarantee Ubuntu origin if another actor has
configured a different higher-priority Node.js repository under another name.
It also does not automatically downgrade an already installed NodeSource package;
such a provider transition requires an explicit migration decision.

### NodeSource provider

NodeSource requires a quoted decimal major channel:

```yaml
nodejs_environments:
  - name: system-node
    scope: system
    state: present
    provider:
      type: nodesource
      channel: "24"
    runtime:
      state: present
      npm_packages:
        - name: corepack
```

The role configures the official `node_<major>.x` repository with suite
`nodistro`, validates that APT selected a candidate from that repository, and
converges the exact candidate package. It does not execute NodeSource setup
scripts or maintain a time-sensitive allowlist of upstream Node.js majors.
Repository prerequisites are managed by the provider.

NodeSource is supported on the Ubuntu releases and architectures declared by
the role. Current architectures are amd64 and arm64.

## npm packages

Packages are global to their runtime by default. An exact package version is
optional:

```yaml
npm_packages:
  - name: pm2
  - name: typescript
    version: "5.9.2"
```

Unversioned packages are installed only when absent. A local package is supported
only for user-scoped runtimes and requires an explicit path:

```yaml
npm_packages:
  - name: typescript
    global: false
    path: /home/web/sites/example/current
```

## Results

The role exposes `nodejs_environment_results`, keyed by environment name. A
managed NVM runtime resembles:

```yaml
nodejs_environment_results:
  web-node:
    name: web-node
    scope: user
    state: present
    user: web
    execution_user: web
    provider:
      type: nvm
      version: v0.40.4
      nvm_dir: /home/web/.nvm
      profile_path: /home/web/.bashrc
    runtime:
      state: present
      version_requested: "24.19"
      version_resolved: v24.19.1
      node_bin: /home/web/.nvm/versions/node/v24.19.1/bin/node
      npm_bin: /home/web/.nvm/versions/node/v24.19.1/bin/npm
      npx_bin: /home/web/.nvm/versions/node/v24.19.1/bin/npx
      bin_dir: /home/web/.nvm/versions/node/v24.19.1/bin
      exec_path: /home/web/.nvm/versions/node/v24.19.1/bin:/usr/local/bin:/usr/bin
```

An unmanaged NVM environment reports provider paths and
`runtime.state: unmanaged`, but no runtime version or executable paths. System
providers report resolved system paths and the installed Node.js version.

Downstream tasks should consume the explicit result paths instead of relying on
an interactive shell or whichever `node` happens to appear first in `PATH`.

## Check mode

On prepared hosts the role inspects the current NVM, Node.js, APT, and npm state.

- A missing NVM target user is reported and user-dependent work is skipped in
  check mode; normal execution fails.
- A fresh NodeSource repository cannot expose its predicted candidate during the
  same check-mode run. Apply the repository layer first, then rerun check mode.
- Runtime results may contain empty executable paths when check mode predicts a
  package or runtime that does not exist yet.

## Non-goals

- User creation.
- Multiple system Node.js package providers on one host.
- Removal of user-installed Node.js versions in an unmanaged NVM environment.
- Systemd unit or lingering management.
- Application deployment.
- PM2-specific service semantics.

## Upstream documentation

- https://github.com/nvm-sh/nvm
- https://github.com/nodesource/distributions
