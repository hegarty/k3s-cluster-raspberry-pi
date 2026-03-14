#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIR="$ROOT_DIR/tests"

TEST_SCRIPTS=(
  "$TEST_DIR/01_context_integrity.sh"
  "$TEST_DIR/02_docs_consistency.sh"
  "$TEST_DIR/03_freshness_policy.sh"
  "$TEST_DIR/10_cluster_smoke.sh"
)

printf "Running repository verification tests...\n"

for test_script in "${TEST_SCRIPTS[@]}"; do
  if [[ ! -x "$test_script" ]]; then
    printf "ERROR: missing or non-executable test script: %s\n" "$test_script" >&2
    exit 1
  fi

  printf "\n==> %s\n" "$(basename "$test_script")"
  "$test_script"
done

printf "\nAll verification tests completed successfully.\n"
