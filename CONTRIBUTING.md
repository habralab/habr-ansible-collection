# Contributing Guidelines

## Development Workflow

We use a feature-branch workflow. All changes must go through Merge Requests to the `develop` branch.

### Branching Model
- `develop` — Main development and integration branch.
- `main` — Production/Release branch (only tagged states).
- `role/<name>` — Feature branches for individual roles.
- `release/vX.Y.Z` — Temporary branches for release preparation.

### Working on a Role
1. Create a branch: `git checkout -b role/my-new-role`.
2. Keep changes scoped to the role directory (`roles/<rolename>/...`)
3. Follow the commit style:
   ```
   <type>(<scope>): <short summary>
   
   - bullet one
   - bullet `code`
   - bullet next
   ```
4. Ensure `ansible-lint` passes: `ansible-lint roles/my-new-role/`.
5. Update documentation:
   - Role README: `roles/<role_name>/README.md`
   - Collection index: Add to the table in `README.md`.

## Release Process

1. **Test**: Ensure linting passes across all versions: run `tox` in
   the collection root.
2. **Prepare**: Create `release/vX.Y.Z` from `develop`.
3. **Pack**: Bump version in `galaxy.yml` and update `CHANGELOG.md`.
4. **Commit**: `chore(release): vX.Y.Z`.
5. **Merge to Main**: Create MR to `main`, then tag it:
   ```bash
   git tag -a vX.Y.Z -m vX.Y.Z && git push --tags
   ```
6. **Sync**: Merge `release/vX.Y.Z` back to develop to sync metadata.
7. **Cleanup**: Delete the release branch.

# Role Design Rules

- Place the role under `roles/<role_name>/`.
- Use FQCN (Fully Qualified Collection Names) for all module calls.
- Always include `meta/main.yml` with correct metadata.
- Ensure `check_mode` support where possible.
