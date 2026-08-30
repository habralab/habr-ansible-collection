# PostgreSQL assets role development

Keep server lifecycle out of this role. Empty role and database contracts must
remain a full no-op, including target Python package installation.

Preserve dependency order: create roles before databases, manage extensions
after databases, and remove roles last. Do not infer deletion from an omitted
asset and do not add migration or seed semantics to an idempotent asset role.

Keep the connection contract usable with local peer authentication and explicit
remote credentials. Never put credentials in role defaults, examples or task
output.
