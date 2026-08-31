#!/usr/bin/env bash
# Run all test playbooks for the nginx role.
# Usage: bash roles/nginx/tests/run.sh [pattern]
#   pattern  optional grep filter on playbook path, e.g. "test_03"
#
# Can be run from any directory.

set -euo pipefail

PATTERN="${1:-}"
TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$TESTS_DIR/../../.." && pwd)"
ANSIBLE_PLAYBOOK="${ANSIBLE_PLAYBOOK:-ansible-playbook}"

playbooks=()
while IFS= read -r playbook; do
  playbooks+=("$playbook")
done < <(
  find "$TESTS_DIR" -name 'test_*.yml' | sort \
    | { [ -n "$PATTERN" ] && grep "$PATTERN" || cat; }
)

if [ "${#playbooks[@]}" -eq 0 ]; then
  echo "No test playbooks found (pattern: '${PATTERN:-*}')"
  exit 1
fi

passed=0
failed=0
failed_files=()

for playbook in "${playbooks[@]}"; do
  rel="${playbook#"$ROOT/"}"
  echo ""
  echo "━━━ $rel"
  if "$ANSIBLE_PLAYBOOK" "$playbook" 2>&1 | tail -5; then
    passed=$(( passed + 1 ))
  else
    failed=$(( failed + 1 ))
    failed_files+=("$rel")
  fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Results: ${passed} passed, ${failed} failed"

if [ "${#failed_files[@]}" -gt 0 ]; then
  echo ""
  echo "Failed:"
  for f in "${failed_files[@]}"; do
    echo "  ✗ $f"
  done
  exit 1
fi
