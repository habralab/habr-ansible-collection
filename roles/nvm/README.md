# NVM (Node Version Manager)

Installs NVM (Node Version Manager) directly from the upstream Git repository for a specific list of users.

## Scope
- Clones NVM to the users' home directories.
- Configures shell profiles (e.g., `.bashrc`) to load NVM environment variables.
- Supports specifying different NVM versions for different users.

## Non-goals
- Node.js runtime installation (this role only installs the version manager).
- Global NPM package management.
- System-wide NVM installation (NVM is designed to be per-user).

## Configuration

The role is driven by a list of dictionaries `nvm_users`.

### Variables

**Global defaults** (can be overridden per user):
- `nvm_version`: Default git tag/version to install (default: `v0.40.4`).
- `nvm_profile`: Default shell profile file to modify (default: `.bashrc`).

**User list (`nvm_users`)**:
A list of dictionaries. Each dictionary must contain `name` and can optionally override `version` and `profile`.

### Example

```yaml
nvm_users:
  - name: "user1"
  - name: "user2"
    version: "v0.39.5"
    profile: ".bash_profile"
```

## Upstream documentation
https://github.com/nvm-sh/nvm
