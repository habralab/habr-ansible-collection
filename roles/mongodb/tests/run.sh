#!/usr/bin/env bash

set -euo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$TESTS_DIR/../../.." && pwd)"
ANSIBLE_PLAYBOOK="${ANSIBLE_PLAYBOOK:-ansible-playbook}"

for playbook in "$TESTS_DIR"/test_*.yml; do
  echo "=== ${playbook#"$ROOT/"} ==="
  ANSIBLE_ROLES_PATH="$ROOT/roles" \
  ANSIBLE_LOCAL_TEMP="${ANSIBLE_LOCAL_TEMP:-/tmp/habr-mongodb-tests}" \
  "$ANSIBLE_PLAYBOOK" "$playbook"
done
