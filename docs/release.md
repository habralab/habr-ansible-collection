# Workflow and release process

This repository is an Ansible collection developed in a private Git repository and mirrored to a public repository for OSS distribution.

## Branches

- `develop` — main development branch (integration, CI, linting)
- `main` — release branch (only tagged, published states)
- `role/<name>` — feature branches for individual roles
- `release/vX.Y.Z` — release preparation branch (version and changelog)

## Working on a role

Create a dedicated branch per role.

Typical commands sequence:

```bash
git checkout develop
git pull
git checkout -b role/<rolename>
```

Rules:

- Keep changes scoped to the role directory (`roles/<rolename>/...`)
- Update documentation together with the role:
 - role README: `roles/<rolename>/README.md`
 - roles index: `docs/roles.md`
- Commit style:

  ```
  <type>(<scope>): <short summary>
  
  - bullet
  - bullet
  - bullet
  ```

- Merge request:
 - source branch: `role/<rolename>`
 - target branch: `develop`
 - CI must pass (lint, tests)

## Release process

Releases are prepared in a dedicated release branch created from `develop`.
The release branch is merged into both `main` and `develop`.

### Step 1: Create release branch from develop

```bash
git checkout develop
git pull
git checkout -b release/vX.Y.Z
```

### Step 2: Release-only changes

In `release/vX.Y.Z`, apply only release packaging changes:

- bump `galaxy.yml` version to `X.Y.Z`
- update `CHANGELOG.md`

Commit message:

```
chore(release): vX.Y.Z
```

### Step 3: Merge release into main

Create merge request:

- source branch: `release/vX.Y.Z`
- target branch: `main`

After merge, tag the release on main:

```bash
git checkout main
git pull
git tag -a vX.Y.Z -m vX.Y.Z
git push --tags
```

### Step 4: Merge release into develop

Create merge request:

- source branch: `release/vX.Y.Z`
- target branch: `develop`

This keeps `develop` in sync with release metadata (version and changelog)
without merging main back.

### Step 5: Cleanup

After both merges:

- delete release/vX.Y.Z branch

## Notes

- `main` must remain release-only; no feature work directly in `main`
- Avoid changing role logic in release branches
- If fixes are required, do them in `develop` (or a hotfix branch), then refresh or recreate the release branch
- `docs/roles.md` must be updated in role branches, not during releases
