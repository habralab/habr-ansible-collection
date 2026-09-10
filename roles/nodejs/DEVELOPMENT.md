# Node.js role architecture

## Public model

`nodejs_environments` describes independently named execution environments. An
environment has one scope, one provider, and one runtime ownership policy.

The role intentionally has no compatibility adapter for the removed
`nodejs_runtimes` contract. All validation completes before provider tasks are
allowed to mutate the host.

## Invariants

- Environment names are unique.
- A host has at most one system environment because Ubuntu and NodeSource both
  own the system `nodejs` package and `/usr/bin/node`.
- A user has at most one NVM environment, while different users remain isolated.
- NVM is user-scoped; Ubuntu and NodeSource are system-scoped.
- `runtime.state=unmanaged` means the role does not inspect or mutate Node.js,
  the NVM default alias, or npm packages. It never means absent.
- Runtime-bound npm operations use paths from `nodejs_environment_result`; they
  must not depend on the controller or remote interactive `PATH`.
- System npm packages are global. Local npm packages require a user environment.

## Execution pipeline

1. Validate the complete public input and cross-environment topology.
2. Initialize `nodejs_environment_results`.
3. Prepare each provider environment.
4. Materialize a managed runtime when requested.
5. Converge npm packages through the resolved runtime.
6. Accumulate a normalized result keyed by environment name.

Provider files own only provider-specific preparation:

- `provider_nvm.yml` owns the NVM checkout and shell profile;
- `provider_ubuntu.yml` owns the Ubuntu package path and removal of the
  role-managed NodeSource source;
- `provider_nodesource.yml` owns the NodeSource repository, pin, and candidate;
- `runtime_nvm.yml` and `runtime_system.yml` resolve runtime state and paths.

## Provider transitions

Selecting Ubuntu removes NodeSource repository and preference artifacts managed
by this role before resolving the Ubuntu APT candidate. Selecting NodeSource
converges its repository and the exact candidate from the requested major
channel.

Removing a system environment from the declaration does not uninstall an
existing system package. Removal semantics are deliberately outside the current
contract.

## Check mode

Provider setup may be predicted while the corresponding runtime remains absent.
Results may therefore contain empty runtime paths during a fresh check-mode run.

A freshly predicted NodeSource source is not visible to `apt-cache`. The role
reports this boundary and skips package/runtime resolution in check mode. On a
prepared host it validates the candidate and predicts normal package changes.

NVM user lookup still executes in check mode. A missing user skips all dependent
work; normal execution fails before attempting a checkout.
