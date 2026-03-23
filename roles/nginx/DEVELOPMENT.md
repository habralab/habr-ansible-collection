# Role: Nginx Development Notes

This document is for contributors working on the role implementation. It complements the role README and focuses on internal design rules, invariants, and extension points.

## Core Invariant

If the role is applied with no custom configuration beyond repository selection, the resulting filesystem state must match the package-provided Nginx layout as closely as possible.

In practice, this means:

- repository selection may change package origin and layout, but should not introduce unrelated config drift on its own
- files that overlap with package-managed paths require especially careful handling
- built-in defaults should preserve package semantics unless the role intentionally overrides them
- new features must not silently rewrite package-shaped files or directories when their input variables are unset

This invariant is one of the main reasons the role keeps strict control over files that intersect with package-managed ones.

## Current Architectural Boundary

The current declarative model is HTTP-oriented.

- `nginx_servers`
- `nginx_auth`
- `nginx_maps`
- `nginx_proxy_*`
- `nginx_real_ip_*`

These are HTTP-layer abstractions. Do not try to stretch them to cover `stream` use cases. If TCP/UDP proxying becomes a real requirement, introduce a parallel namespace instead of mutating the current HTTP model.

## How to Read Legacy

Files prefixed with `imported_` are reference material, not design targets.

- use them to discover real-world edge cases and existing operational patterns
- do not copy their structure into the new API
- if a new abstraction starts looking too much like `imported_*`, the role is probably pulling legacy back into the model

## Naming Rules

- all role-level variables must use the `nginx_` prefix
- prefer names that reflect actual nginx semantics
- avoid over-general names when the implementation is HTTP-specific
- do not over-abstract names for hypothetical future contexts

The goal is explicitness without painting the role into a corner.

## Registry-Driven Role Design

This role is built around internal dictionaries more than around ad hoc task branches.

Important registries live in `vars/main.yml`:

- `__nginx_repositories_defaults`
- `__nginx_layouts_config`
- `__nginx_dropins`
- `__nginx_server_template_specs`

When adding a feature, first decide which registry it belongs to:

- new package source or packaging flavor: repository defaults
- layout-sensitive behavior: layout config
- singleton HTTP config rendered into `conf.d`: drop-ins registry

If a feature requires many scattered `when` conditions, it is usually a sign that it wants a dictionary-backed registry instead.

## Layout First, Conditions Second

The role is intentionally layout-driven.

Repository choice determines the active layout, and the active layout determines:

- runtime user and group
- managed directories
- core files
- include paths
- server config placement
- symlink policy
- logging-related defaults

If a new feature depends on paths, directory layout, symlink behavior, or package conventions, model it through the layout dictionaries instead of sprinkling conditional logic across tasks.

## Package-Parity and Managed Scope

Be conservative about what the role manages.

- clean up only the artifacts that belong to the specific managed layer
- do not introduce broad orphan removal for package-owned or semi-manual areas
- absent-state cleanup is good when the role owns the artifact name
- global cleanup is risky when the role cannot prove ownership

This role is intentionally not destructive by default.

## Singleton vs List-Driven Features

The role already has two clear patterns:

- singleton HTTP features rendered as one drop-in file
- list-driven resources rendered as one file per object

Typical singleton features:

- proxy settings
- real IP settings
- maps

Typical list-driven features:

- server configs
- auth include companions

Choose the pattern based on the lifecycle of the feature, not on implementation convenience.

## Includes vs Drop-Ins

Use managed includes for reusable pieces that are explicitly referenced by another template.

Use drop-ins for global HTTP declarations that should simply exist in `conf.d`.

Examples:

- auth bundles belong to `/etc/nginx/includes`
- maps belong to `conf.d`

If a feature is not meant to be explicitly `include`d from a server or location template, it probably should not live in the managed includes namespace.

## Controlled Escape Hatches

The role already allows limited raw nginx syntax in a few places. This is intentional.

Examples include:

- extra lines in server templates
- explicit include directives
- selective raw-like fields for complex directives

Do not rush to model every nginx directive as a first-class variable. A controlled escape hatch is often better than a premature and unstable schema.

## Auth Model

Treat auth as a bundle, not as a synonym for `auth_basic`.

- `access` and `basic` are separate mechanisms
- IP-based access control and HTTP Basic Auth must remain independently expressible
- password companions should only exist when basic auth is actually configured
- empty passwd files are an anti-pattern

Keep user credentials in shared passwd lists. Do not reintroduce inline user lists into the new API.

## Access Model

Access rules should be built from named `nginx_ip_sets`, not from ad hoc raw prefixes.

Key rules:

- keep rule order explicit
- keep action explicit on each referenced set
- keep a terminal rule explicit through `default_action`
- default to `deny` when access control is enabled unless a feature specifically needs allow-by-default behavior

The model should make ACL intent obvious without requiring synthetic catch-all IP sets.

## Maps Model

Maps are currently optimized for safe rendering, not for maximum raw flexibility.

- render `default`, `match`, and `value` as single-quoted strings
- prefer single-quoted YAML strings for regex-heavy patterns
- if a future use case needs raw or expression-oriented rendering, add it as an explicit mode instead of weakening the current safe default

This tradeoff is intentional. Regex-heavy maps are common enough to justify a conservative baseline.

## Default Server Merge Semantics

Bundled default servers and user-defined servers are merged by `name`.

This means:

- `name` acts as the identity key
- a user can override a bundled server by reusing its name
- `filename` is not the primary identity in merge logic

Keep this in mind when introducing new built-in servers or renaming existing ones.

## Iterative Server Rollout Filter

The role supports narrow rollout of server entries through `nginx_only_servers`.

Rules:

- treat it as an operational filter over the already-merged `nginx_servers` list
- keep the public API CLI-first: a single pattern or a comma-separated string with shell-style `*`
- continue accepting structured lists as a compatibility fallback
- do not expose raw regex as the primary interface
- match against `name`, `filename`, and `server_name`
- apply the same filter to `present` and `absent` entries so targeted runs do not accidentally remove unrelated files

If future selection needs become more complex, prefer adding one more explicit matching surface over turning the variable into a mini query language.

## Handler Semantics Matter

The role validates config through `nginx -t` before reload or restart.

For contributors, this means:

- template rendering success is not enough
- syntax-sensitive features should be designed to fail early and predictably
- complex generated syntax should be treated with extra care even if Jinja rendering looks correct

This is especially relevant for regex-heavy maps, log format fragments, and raw-ish extension points.

## Check Mode Is Part of the Contract

Some tasks already behave differently in check mode, especially around symlinks and service control.

New features should be designed with check mode in mind:

- avoid false-positive failures where practical
- avoid pretending state changes succeeded when they cannot be simulated safely
- keep operational behavior understandable during dry runs

## Platform Assumptions

The role metadata currently targets Ubuntu and requires Ansible 2.15+.

Do not add portability complexity unless there is an actual supported target that needs it. This role already has enough moving parts in repository and layout handling without pretending to be cross-distro by default.

## Practical Rule of Thumb

When adding something new, answer these questions first:

1. Is it HTTP-specific, or is it a future parallel namespace candidate?
2. Is it package-layout-sensitive?
3. Is it a singleton drop-in or a list-driven resource?
4. Is it a reusable include or a global declaration?
5. Does it preserve the package-parity invariant when left unset?

If those answers are unclear, the data model is probably not ready yet.

## Bundled Template: `servers/vhost`

The points below are specific to the bundled `servers/vhost` template and should not be treated as role-wide rules.

### Internal Model

`servers/vhost` is currently driven by a template-specific registry layer loaded through `__nginx_server_template_specs`.

The active internal registries for this template are:

- `__nginx_server_vhost_directive_specs`
- `__nginx_server_vhost_block_specs`
- `__nginx_server_vhost_context_specs`
- `__nginx_server_vhost_mode`

Supporting files:

- `vars/server_vhost.yml`
- `templates/servers/vhost.j2`

### Extension Rules

When extending `servers/vhost`, prefer:

1. add or adjust directive metadata in the directive registry
2. place the directive into the correct logical block
3. extend composite rendering only when a normal renderer type is insufficient

Do not add another hardcoded template branch unless the current data model genuinely cannot express the behavior.

### Renderer Categories

Current renderer categories used by `servers/vhost` include:

- `scalar`
- `repeatable`
- `join_space`
- `bool_on_off`
- `name_value_list`
- `proxy_buffers`
- composite renderers for schema-driven or multi-line constructs

Use a composite renderer only when a normal typed renderer is insufficient.

### Escape Hatches

For `servers/vhost`, `extra` is the narrow escape hatch.

- use it for exceptional raw lines
- do not use it as the default answer for every missing directive
- if the same raw pattern appears repeatedly, it probably wants a real renderer

### Debug Mode

`servers/vhost` currently has an explicit internal debug mode via `__nginx_server_vhost_mode`.

Current implementation facts:

- debug block markers and inline debug annotations are implemented
- production rendering and debug rendering share helpers
- inline debug annotations are the preferred form once a renderer becomes usable

This is template-internal machinery, not a role-wide API guarantee.

### Current Status Boundary

The template is already functional for the main declarative HTTP vhost path, but not every field present in the registries has been exercised by real inventory yet.

Also note:

- `ssl_provisioning` is currently mock-only in tasks
- `ssl_files` is authoritative for rendered certificate paths in `servers/vhost`
- legacy `imported_*` templates remain reference material for edge cases and feature discovery, not structural targets

### Development Rule of Thumb

When working on `servers/vhost`:

1. prefer changing the template model before changing template control flow
2. keep user-facing fields documented in the role README
3. keep template-specific rules in this section instead of spreading them across the whole role development document
4. treat a clean-looking YAML model that renders broken nginx syntax as a failed design
