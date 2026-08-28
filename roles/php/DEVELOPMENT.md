# PHP role development

The role supports Ubuntu Focal and newer, but repository availability is a
separate concern. Do not encode a promise that every PHP version exists for
every Ubuntu release. Package availability remains APT's authority.

Application roles must not mutate `/etc/php`. New settings belong in the
versioned `90-ansible.ini` files or role-managed FPM pool fragments.

Keep repository configuration host-scoped and installation/configuration
version-scoped. Always treat PHP versions as strings, and do not implicitly
change the default CLI when adding another version.

Runtime extension checks are opt-in. Keep them generic: package sources and
extension-specific installation policy belong in inventory, not in this role.
