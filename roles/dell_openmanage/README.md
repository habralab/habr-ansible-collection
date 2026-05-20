# Dell OpenManage (`dell_openmanage`)

Configure Dell OpenManage community APT repositories and install selected Dell
packages. The role currently manages iDRAC Service Module (iSM) for Ubuntu LTS
hosts.

## Defaults

The default profile installs `dcism` from Dell iSM repositories. Repository
selection is keyed by `dell_openmanage_generation` and Ubuntu release.

The matrix below is based on the Dell OpenManage Ubuntu and Debian repositories
availability matrix as of 2026-05-20:
<https://linux.dell.com/repo/community/openmanage/>

| Generation | Ubuntu release | Dell iSM repository |
| --- | --- | --- |
| 14 | focal | `http://linux.dell.com/repo/community/openmanage/iSM/4300/focal` |
| 14 | jammy | `http://linux.dell.com/repo/community/openmanage/iSM/5300/jammy` |
| 14 | noble | `http://linux.dell.com/repo/community/openmanage/iSM/5400/noble` |
| 15 | focal | `http://linux.dell.com/repo/community/openmanage/iSM/4300/focal` |
| 15 | jammy | `http://linux.dell.com/repo/community/openmanage/iSM/5300/jammy` |
| 15 | noble | `http://linux.dell.com/repo/community/openmanage/iSM/6100/noble` |
| 16 | jammy | `http://linux.dell.com/repo/community/openmanage/iSM/5300/jammy` |
| 16 | noble | `http://linux.dell.com/repo/community/openmanage/iSM/6100/noble` |
| 17 | noble | `http://linux.dell.com/repo/community/openmanage/iSM/6100/noble` |

NB: this role intentionally manages only iDRAC Service Module (iSM). OMSA and
DTK repository support is not planned because OMSA is in EOL status and DTK is a
legacy toolchain.

The role delegates APT source management to `habr.linuxhost.apt_repo`, using the
repository name from `dell_openmanage_ism_repository_name` and the keyring from
`dell_openmanage_repository_keyring`.

After package installation, the role enables and starts `dcismeng.service`.

## Variables

- `dell_openmanage_repository_state`: Repository state, defaults to `present`.
- `dell_openmanage_repository_key_url`: Dell repository signing key URL.
- `dell_openmanage_repository_keyring`: Local apt keyring path.
- `dell_openmanage_manage_ism`: Manage the iSM repository, defaults to `true`.
- `dell_openmanage_install_packages`: Install packages after configuring the
  repository, defaults to `true`.
- `dell_openmanage_manage_ism_service`: Enable and start `dcismeng.service`,
  defaults to `true`.
- `dell_openmanage_generation`: Dell PowerEdge generation used for selecting
  the repository matrix, defaults to `"17"`.
- `dell_openmanage_ism_repository_matrix`: Per-generation and per-release
  repository matrix.
- `dell_openmanage_ism_packages_extra`: Extra packages to install together with
  the release defaults.

## Example

```yaml
- name: Dell OpenManage iSM
  hosts: dell_openmanage_hosts
  roles:
    - habr.linuxhost.dell_openmanage
  vars:
    dell_openmanage_generation: "14"
```
