# RUNBOOK.md

## Purpose
Operational runbook for provisioning, operating, and recovering this repository's k3s Raspberry Pi cluster.

Status: scaffold (procedures are placeholders until validated end-to-end)
Last updated: 2026-03-08

## Scope
In scope:
- cluster bootstrap and lifecycle operations
- day-2 cluster operations
- validation and troubleshooting

Out of scope:
- application code changes
- application Helm chart authoring

## Environment
- Cluster topology: single-node (`pi-1.local`)
- Primary SSH target: `pi-1.local`
- Runtime architecture: `arm64`
- Exposure model: LAN-only

## Preconditions
Document exact prerequisites and versions here.

Checklist:
- [ ] local tools installed
- [ ] SSH connectivity confirmed
- [ ] target node baseline state confirmed
- [ ] kubeconfig target location agreed

## Canonical Commands
Current command surface (provisional):

```bash
make k3s-install
make k3s-start
make k3s-stop
make kubeconfig-sync
```

Record exact expected output for each command once validated.

## Procedure: Bootstrap (Placeholder)
Goal: create a functioning k3s cluster on a clean Raspberry Pi host.

Steps:
1. Confirm prerequisites.
2. Execute bootstrap command path.
3. Sync kubeconfig.
4. Run post-bootstrap validation.

Validation (to be finalized):
- `kubectl get nodes -o wide`
- `kubectl get pods -A`
- `kubectl cluster-info`

## Procedure: Start Cluster (Placeholder)
Steps:
1. Run `make k3s-start`.
2. Verify control plane availability.
3. Verify core components are healthy.

Validation:
- `kubectl get nodes`
- `kubectl get pods -A`

## Procedure: Stop Cluster (Placeholder)
Steps:
1. Run `make k3s-stop`.
2. Confirm services are stopped.
3. Confirm expected impact boundaries.

Validation:
- service status checks (define exact commands)

## Procedure: Kubeconfig Sync (Placeholder)
Steps:
1. Run `make kubeconfig-sync`.
2. Confirm local kubeconfig context.
3. Confirm API connectivity.

Validation:
- `kubectl config current-context`
- `kubectl get ns`

## Procedure: Upgrade (Placeholder)
Define upgrade workflow, prechecks, and rollback trigger.

Checklist:
- [ ] backup/state capture complete
- [ ] upgrade command path defined
- [ ] post-upgrade validation defined
- [ ] rollback path tested

## Recovery Playbooks (Placeholder)
### Node reboot recovery
Define expected automatic recovery behavior and validation.

### Control plane unavailable
Define diagnostics, restart path, and escalation conditions.

### Networking issues
Define flannel/CNI checks and LAN-level diagnostics.

## Troubleshooting Matrix (Placeholder)
| Symptom | Likely cause | Diagnostics | Fix |
|---|---|---|---|
| `kubectl` cannot connect | kubeconfig/context mismatch | `kubectl config current-context` | resync kubeconfig |
| Node `NotReady` | runtime or network issue | `kubectl describe node` | restart services, inspect logs |
| Pods pending | resource/storage constraints | `kubectl get events -A` | tune resources/storage |

## Change Log
- 2026-03-08: Initial scaffold created.
