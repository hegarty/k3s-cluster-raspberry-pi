#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR"

ruby - <<'RUBY'
require 'yaml'
require 'date'

doc = YAML.load_file('claude.md')
metadata = doc.fetch('metadata')

last_updated = Date.iso8601(metadata.fetch('last_updated').to_s)
next_review = Date.iso8601(metadata.fetch('next_review_due').to_s)

today = Date.today

if next_review < last_updated
  warn "next_review_due (#{next_review}) is earlier than last_updated (#{last_updated})"
  exit 1
end

if last_updated > today
  warn "last_updated (#{last_updated}) cannot be in the future relative to #{today}"
  exit 1
end

if next_review < today
  warn "next_review_due (#{next_review}) is in the past relative to #{today}"
  exit 1
end

sections = {
  'secrets.last_reviewed' => doc.dig('secrets', 'last_reviewed'),
  'image_registry.last_reviewed' => doc.dig('image_registry', 'last_reviewed'),
  'ingress.tls.last_reviewed' => doc.dig('ingress', 'tls', 'last_reviewed'),
  'runtimes.k3s.persistence_strategy.backup_strategy.last_reviewed' => doc.dig('runtimes', 'k3s', 'persistence_strategy', 'backup_strategy', 'last_reviewed')
}

sections.each do |path, value|
  begin
    Date.iso8601(value.to_s)
  rescue ArgumentError
    warn "Invalid ISO date at #{path}: #{value.inspect}"
    exit 1
  end
end

puts 'Freshness policy checks: OK'
RUBY

printf "Freshness policy checks passed.\n"
