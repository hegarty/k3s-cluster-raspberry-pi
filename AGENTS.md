# AGENTS.md

## Purpose
This file is the primary entrypoint for coding agents working in this repository.
Use it for operational guidance and constraints.

Detailed architecture and long-form context live in:
- `claude.md` (canonical architecture and decision reference)
- `RUNBOOK.md` (operational procedures and recovery playbooks)
- `tests/TESTS.md` (verification suite and execution policy)

## Repository Scope
This repository manages edge cluster infrastructure for k3s on Raspberry Pi.

In scope:
- k3s cluster provisioning and lifecycle operations
- node bootstrap and cluster-level infrastructure
- namespace and cluster networking setup
- ingress controller and cluster observability

Out of scope:
- application source code
- application Dockerfiles and image build pipelines
- application Helm charts and app-specific manifests

## Current Operating Status
Operating model is still being built.

Current state:
- `RUNBOOK.md` exists as a scaffold and is being filled incrementally
- `how_to_operate_repo` in `claude.md` tracks completion goals
- no finalized runbook yet

Work that must be completed next:
- define local prerequisites and versions
- define clean-host bootstrap flow
- define day-2 operations (start/stop/upgrade/recover)
- define validation checks and rollback procedures

## Known Commands (Provisional)
Use available Make targets as the current operational surface:
- `make k3s-install`
- `make k3s-start`
- `make k3s-stop`
- `make kubeconfig-sync`

Treat behavior and output expectations as provisional until runbook docs are finalized.

## Verification Workflow
Run verification before handing work back:

1. `./tests/run-all.sh`
2. `RUN_CLUSTER_TESTS=1 ./tests/run-all.sh` for cluster-affecting changes

If a test fails, update docs/code and rerun until green.

## Constraints
- cluster topology is currently single-node: `pi-1.local`
- primary SSH target: `pi-1.local`
- architecture baseline: `arm64` (dev and deploy)
- network exposure: LAN only, no public internet exposure
- keep workloads lightweight for Raspberry Pi resource limits

## Open Decisions
These are pending and should not be assumed as finalized:
- secrets strategy
- image registry implementation details
- TLS strategy
- backup strategy

Reference decision status in `claude.md` before implementing related changes.

## Update Rules
When making meaningful infrastructure changes:
1. update `AGENTS.md` if operating instructions or constraints changed
2. update `claude.md` if architecture, decisions, or status changed
3. refresh freshness dates in `claude.md` metadata and relevant sections
4. update `tests/TESTS.md` and related scripts when verification policy changes

## Canonical References
- Architecture and principles: `claude.md`
- Operations and recovery procedures: `RUNBOOK.md`
- Verification suite and policy: `tests/TESTS.md`
- Runtime details: `claude.md` sections `runtimes`, `raspberry_pi_requirements`
- Multi-arch strategy: `claude.md` section `build_and_images.multi_arch_strategy`
- Operating placeholder: `claude.md` section `how_to_operate_repo`
