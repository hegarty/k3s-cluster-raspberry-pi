# Tests Guide

This directory contains the verification tests that Claude (and Codex) should run to validate repository changes.

The test surface is intentionally command-first, similar to `edge-monitor-app`: one canonical entrypoint plus focused checks.

## Quick Start

Run all default verification checks:

```bash
./tests/run-all.sh
```

Run with live cluster smoke checks enabled:

```bash
RUN_CLUSTER_TESTS=1 ./tests/run-all.sh
```

## Test Inventory

- `01_context_integrity.sh`
  - Ensures required context files exist.
  - Parses `claude.md` as YAML.
  - Verifies critical top-level keys are present.

- `02_docs_consistency.sh`
  - Ensures `AGENTS.md` references canonical docs.
  - Verifies canonical Make commands are documented in `RUNBOOK.md`.
  - Verifies `claude.md` metadata points to the right context files.
  - Verifies required make targets exist in `claude.md`.

- `03_freshness_policy.sh`
  - Validates freshness dates in `claude.md`.
  - Ensures `next_review_due` is not stale or invalid.
  - Verifies `last_reviewed` dates in decision areas are ISO-8601.

- `10_cluster_smoke.sh`
  - Optional live cluster checks using `kubectl`.
  - Skipped by default unless `RUN_CLUSTER_TESTS=1`.

## CI / Agent Usage Pattern

For documentation-only changes, run:

```bash
./tests/run-all.sh
```

For operational or cluster-affecting changes, run:

```bash
RUN_CLUSTER_TESTS=1 ./tests/run-all.sh
```

## Exit Behavior

- Any failing check exits non-zero.
- `run-all.sh` stops at the first failure.
- Cluster smoke tests are safe-by-default (opt-in).
