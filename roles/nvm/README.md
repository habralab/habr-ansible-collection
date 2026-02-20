# NVM (Node Version Manager)

Installs NVM (Node Version Manager) directly from the upstream Git repository for a specific user.

## Scope
- Clones NVM to the specified user's home directory.
- Configures `.bashrc` and `.profile` to load NVM environment variables.
- Checks out a specific tagged version of NVM.

## Non-goals
- Node.js runtime installation (this role only installs the version manager).
- Global NPM package management.
- System-wide NVM installation (NVM is designed to be per-user).

## Configuration

See `defaults/main.yaml` for all variables. Key variables include:
- `nvm_user`: The Linux user who will own the NVM installation (default: `web`).
- `nvm_version`: The git tag/version to install (default: `v0.40.2`).

## Upstream documentation
https://github.com/nvm-sh/nvm
