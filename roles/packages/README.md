# Packages

Utility role to declaratively manage system packages via APT. Ideal for satisfying prerequisites for various applications.

## Scope

- Setup custom APT repositories (legacy `.list` and modern `deb822`).
- Fast, bulk installation of standard packages from configured APT repositories.
- Installation of `.deb` packages from direct URLs.
- Bulk removal of packages, including unused dependencies (`autoremove`).

## Variables

- `packages_custom_repos`: List of dictionaries defining custom APT repositories (default: `[]`).
  Under the hood, this uses the `apt_repo` helper role.
- `packages_install_common`: List of base packages to install everywhere (default: `[]`).
- `packages_install_extra`: List of specific packages to install for a group/host (default: `[]`).
- `packages_install_urls`: List of URLs pointing to `.deb` files (default: `[]`).
- `packages_remove_list`: List of package names to remove (default: `[]`).

## Example

```yaml
packages_custom_repos:
  - name: "docker"
    url: "https://download.docker.com/linux/{{ ansible_distribution | lower }}"
    components: ["stable"]
    key_url: "https://download.docker.com/linux/{{ ansible_distribution | lower }}/gpg"

packages_install_common:
  - htop
  - curl

packages_install_extra:
  - nginx

packages_install_urls:
  - "https://github.com/derailed/k9s/releases/download/v0.32.4/k9s_linux_amd64.deb"
```
