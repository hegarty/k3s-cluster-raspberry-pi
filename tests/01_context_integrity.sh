#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

required_files=(
  "$ROOT_DIR/AGENTS.md"
  "$ROOT_DIR/claude.md"
  "$ROOT_DIR/RUNBOOK.md"
  "$ROOT_DIR/tests/TESTS.md"
)

for f in "${required_files[@]}"; do
  [[ -f "$f" ]] || { printf "Missing required file: %s\n" "$f" >&2; exit 1; }
done

ruby - <<'RUBY'
require 'yaml'
path = 'claude.md'
doc = YAML.load_file(path)
required = %w[metadata project how_to_operate_repo verification]
missing = required.reject { |k| doc.key?(k) }
if missing.any?
  warn "Missing top-level keys in #{path}: #{missing.join(', ')}"
  exit 1
end
puts 'claude.md YAML structure: OK'
RUBY

printf "Context integrity checks passed.\n"
