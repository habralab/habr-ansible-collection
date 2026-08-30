# Python virtual environments

Creates application-owned Python virtual environments and installs explicitly
pinned Python dependencies. The role does not install Python interpreters or
configure package repositories.

## Requirements

The declared user, group, Python executable, and the interpreter's `venv`
module must already exist. Use the collection's `users`, `apt_repo`, and
`packages` roles to provide those prerequisites.

For example, Ubuntu releases that provide Python 3.10 can install
`python3.10` and `python3.10-venv` from APT. If a selected Ubuntu release does
not provide that version, configure an explicit external repository before
running this role.

## Variables

- `python_venv_environments`: list of virtual environment declarations (default: `[]`). An
  empty list is a no-op.

Each declaration requires:

- `name`: unique result key;
- `path`: absolute virtual environment path;
- `python`: absolute source interpreter path;
- `user` and `group`: existing runtime owner.

Optional fields:

- `mode`: virtual environment directory mode (default: `0755`);
- `requirements`: list of exact `name==version` pins;
- `requirements_file`: existing remote requirements file;
- `pip_extra_args`: additional arguments passed to pip.

`requirements` and `requirements_file` are mutually exclusive. Use a
requirements file for hashes, environment markers, direct URLs, or constraints.
The role does not inspect the file contents, so that file must contain the
required pins itself.

## Example

```yaml
python_venv_environments:
  - name: example-worker
    path: /opt/example-worker/venv
    python: /usr/bin/python3.10
    user: example-worker
    group: example-worker
    requirements:
      - httpx==0.28.1
      - uvicorn==0.35.0
```

No interpreter version is selected implicitly. Repository selection and
system package versions remain explicit inventory policy.

## Runtime results

For non-empty input, the role exposes `python_venv_results` keyed by declaration
name. Each result contains the virtual environment path, source interpreter,
owner, and absolute `python`, `pip`, and `bin_dir` paths. Downstream application
and systemd roles should use these paths directly.

## Non-goals

- Python interpreter or pyenv installation;
- Unix user creation;
- application, model, or requirements-file deployment;
- systemd unit management;
- automatic pip or build-tool upgrades.
