# Python virtual environment role development

Keep interpreter acquisition separate from virtual environment provisioning.
Adding a repository, pyenv provider, application deployment, or service
lifecycle to this role requires a separate use case and contract.

Inline requirements deliberately accept only exact `name==version` pins.
Complex pip syntax belongs in a consumer-owned requirements file.
