#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

required_refs=(
  "claude.md"
  "RUNBOOK.md"
  "tests/TESTS.md"
)

for ref in "${required_refs[@]}"; do
  grep -qF "$ref" "$ROOT_DIR/AGENTS.md" || {
    printf "AGENTS.md is missing required reference: %s\n" "$ref" >&2
    exit 1
  }
done

required_commands=(
  "make k3s-install"
  "make k3s-start"
  "make k3s-stop"
  "make kubeconfig-sync"
)

for cmd in "${required_commands[@]}"; do
  grep -qF "$cmd" "$ROOT_DIR/RUNBOOK.md" || {
    printf "RUNBOOK.md is missing command: %s\n" "$cmd" >&2
    exit 1
  }
done

ruby - <<'RUBY'
require 'yaml'
doc = YAML.load_file('claude.md')
related = doc.dig('metadata', 'related_context_files') || {}
expected = {
  'agent_entrypoint' => 'AGENTS.md',
  'operations_runbook' => 'RUNBOOK.md',
  'tests_guide' => 'tests/TESTS.md'
}
expected.each do |k, v|
  unless related[k] == v
    warn "claude.md metadata.related_context_files.#{k} expected #{v.inspect}, got #{related[k].inspect}"
    exit 1
  end
end

targets = doc.dig('makefile', 'targets') || {}
required_targets = %w[k3s-install k3s-start k3s-stop kubeconfig-sync]
missing = required_targets.reject { |t| targets.key?(t) }
if missing.any?
  warn "claude.md makefile.targets missing: #{missing.join(', ')}"
  exit 1
end

puts 'Documentation consistency checks: OK'
RUBY

printf "Documentation consistency checks passed.\n"
