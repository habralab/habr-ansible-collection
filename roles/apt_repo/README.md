# APT Repository Helper (`apt_repo`)

Helper role to safely manage APT repositories, supporting both legacy `.list` and modern `deb822` formats. 
Designed to be consumed internally by other roles via `include_role`.

## Variables

The role expects a single dictionary named `apt_repo_config` containing the repository definition.

### `apt_repo_config` keys:
- `name` **(required)**: Short name of the repository (used for filenames).
- `url` **(required)**: URL of the repository.
- `state`: `present` or `absent` (default: `present`).
- `types`: List of repository types (default: `["deb"]`).
- `components`: List of distribution components (default: `["main"]`).
- `arch`: Architecture restriction (default: `amd64`).
- `suite`: Distribution suite. Use trailing slash for flat repositories.
- `key_url`: Direct URL to a GPG key. For modern Deb822 repositories this is
  passed to `deb822_repository`, which downloads a repository-scoped key into
  `/etc/apt/keyrings`. On the legacy `.list` path it is imported with
  `apt_key` into `keyring`.
- `key_server`: Keyserver URL (default: `keyserver.ubuntu.com`).
- `key_ids`: List of GPG key IDs to fetch from the keyserver. This legacy
  interface is supported only on Ubuntu older than 22.04; modern Deb822
  repositories must provide `key_url`.
- `keyring`: Path to save the GPG keyring (default: `/etc/apt/keyrings/<name>.gpg`).

*Note: Global fallback defaults (like `apt_repo_types`, `apt_repo_arch`) can be overridden at the playbook level if needed.*

## Example

```yaml
- name: Configure custom APT repository
  ansible.builtin.include_role:
    name: habr.linuxhost.apt_repo
  vars:
    apt_repo_config:
      name: "docker"
      url: "https://download.docker.com/linux/{{ ansible_distribution | lower }}"
      components: ["stable"]
      key_url: "https://download.docker.com/linux/{{ ansible_distribution | lower }}/gpg"
```
