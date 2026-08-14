# Node.js

Declaratively provisions Node.js runtimes and runtime-bound npm packages.

This role replaces the former `nvm` role. NVM is now an internal provider used
to materialize a complete Node.js runtime rather than a separate public
contract.

## Scope

- Install and configure NVM for a target user.
- Install a requested Node.js version and select it as the NVM default.
- Resolve explicit `node`, `npm`, and `npx` executable paths.
- Optionally converge npm packages through the resolved runtime.
- Expose normalized runtime results for downstream roles and tasks.

## Supported Runtime

The initial implementation supports:

- `provider: nvm`
- `scope: user`
- `state: present`

Other providers and removal semantics are not part of the current contract.

## Variables

- `nodejs_runtimes`: Non-empty list of runtime declarations.
- `nodejs_nvm_version`: Default NVM git tag (default: `v0.40.4`).
- `nodejs_nvm_profile`: Default user profile managed for NVM (default: `.bashrc`).
- `nodejs_nvm_repo`: NVM git repository URL.

Each runtime requires:

- `name`: Unique result key.
- `provider`: Currently `nvm`.
- `scope`: Currently `user`.
- `user`: Existing target user.
- `version`: Node.js version or NVM version selector.
- `state`: Currently `present`.

Optional runtime fields:

- `nvm_version`: Override the NVM git tag for this runtime.
- `profile`: Override the managed profile path relative to the user home.
- `npm_packages`: Packages installed through this runtime.

## Example

```yaml
nodejs_runtimes:
  - name: "web-main"
    provider: "nvm"
    scope: "user"
    user: "web"
    version: "22"
    state: "present"
    npm_packages:
      - name: "pm2"
      - name: "typescript"
        version: "5.9.2"
```

Npm packages are global by default. A local package requires `global: false`
and an explicit `path`:

```yaml
npm_packages:
  - name: "typescript"
    global: false
    path: "/srv/example"
```

## Runtime Results

The role exposes results through `nodejs_runtime_results`, keyed by runtime
name. Downstream code should use these explicit paths instead of relying on an
interactive shell profile:

```yaml
nodejs_runtime_results:
  web-main:
    provider: "nvm"
    user: "web"
    version_requested: "22"
    version_resolved: "v22.23.2"
    node_bin: "/home/web/.nvm/versions/node/v22.23.2/bin/node"
    npm_bin: "/home/web/.nvm/versions/node/v22.23.2/bin/npm"
    npx_bin: "/home/web/.nvm/versions/node/v22.23.2/bin/npx"
    bin_dir: "/home/web/.nvm/versions/node/v22.23.2/bin"
    exec_path: "/home/web/.nvm/versions/node/v22.23.2/bin:/usr/local/bin:/usr/bin"
```

## Migration From `nvm`

The old `nvm_users` contract is not compatible field-for-field:

- old `nvm_users[].version` selected the NVM release;
- new `nodejs_runtimes[].version` selects the Node.js runtime;
- use `nodejs_runtimes[].nvm_version` to override the NVM release.

## Check Mode

On prepared hosts the role inspects the current NVM, Node.js, and npm state.
If the target user is absent, check mode reports that user-dependent work was
skipped; normal execution fails with a clear prerequisite error.

## Non-goals

- User creation.
- Systemd unit or lingering management.
- Application deployment.
- PM2-specific service semantics.

## Upstream Documentation

https://github.com/nvm-sh/nvm
