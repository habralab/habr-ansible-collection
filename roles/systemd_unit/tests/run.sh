#!/usr/bin/env bash

set -euo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
COLLECTION_ROOT="$(cd "$TESTS_DIR/../../.." && pwd)"
ANSIBLE_PLAYBOOK="${ANSIBLE_PLAYBOOK:-ansible-playbook}"

for test_file in "$TESTS_DIR"/test_*.yml; do
  echo "Running ${test_file#$COLLECTION_ROOT/}"
  ANSIBLE_ROLES_PATH="$COLLECTION_ROOT/roles" "$ANSIBLE_PLAYBOOK" "$test_file"
done
