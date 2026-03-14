# k3s Cluster — Raspberry Pi

Provisions and manages a single-node [k3s](https://k3s.io) Kubernetes cluster on a Raspberry Pi 5 (arm64). The cluster runs on the local LAN only and is fully reproducible from this repository using Ansible and Helm.

This repository owns cluster infrastructure only — application source code, Dockerfiles, and Helm charts live in their respective application repositories.

## What's in this repo

| Path | Purpose |
|---|---|
| `playbooks/` | Ansible playbooks for bootstrapping and deploying the cluster |
| `helm/` | Helm chart values and local charts deployed to the cluster |
| `inventory/` | Ansible inventory (target: `pi-1.local`) |
| `scripts/` | Operational helper scripts |
| `tests/` | Verification test suite |
| `plans/` | Execution plans for provisioning and deployment |

## Prerequisites

Run the check script to confirm all local and node requirements are met:

```bash
bash scripts/check-prereqs.sh
```

See `plans/01-INIT.md` for the full prerequisites table and install instructions for anything missing.

## Usage

To run manually at any point:

```bash
# Prerequisites
bash scripts/check-prereqs.sh

# Plan 01 — provision k3s
make k3s-install
make kubeconfig-sync

# Plan 02 — deploy application layer
make apps-deploy
```

The playbooks are idempotent — re-running them is safe and will only apply what has changed.

## What's running on the cluster

```
┌────────────────┬──────────────────────────────┬────────────────────────────────────────────────────────┐
│   Namespace    │          Component           │                         Notes                          │
├────────────────┼──────────────────────────────┼────────────────────────────────────────────────────────┤
│ kube-system    │ Traefik (ingress)            │ Running — EXTERNAL-IP: 192.168.1.200 via MetalLB       │
├────────────────┼──────────────────────────────┼────────────────────────────────────────────────────────┤
│ metallb-system │ MetalLB controller + speaker │ Running                                                │
├────────────────┼──────────────────────────────┼────────────────────────────────────────────────────────┤
│ monitoring     │ Prometheus                   │ Running — node Ready = 1                               │
├────────────────┼──────────────────────────────┼────────────────────────────────────────────────────────┤
│ monitoring     │ Grafana                      │ Running — accessible via Traefik at grafana.pi-1.local │
└────────────────┴──────────────────────────────┴────────────────────────────────────────────────────────┘
```

## Make targets

| Target | Description |
|---|---|
| `make k3s-install` | Bootstrap OS and install k3s on the node |
| `make k3s-start` | Start k3s service |
| `make k3s-stop` | Stop k3s service |
| `make kubeconfig-sync` | Pull kubeconfig from node into `~/.kube/config` |
| `make apps-deploy` | Deploy MetalLB, Prometheus, and Grafana via Helm |

## Verification

```bash
# Docs and config checks
./tests/run-all.sh

# Full check including live cluster
RUN_CLUSTER_TESTS=1 ./tests/run-all.sh
```

## Node

| | |
|---|---|
| Hardware | Raspberry Pi 5 (8GB) |
| OS | Debian GNU/Linux 13 (trixie) |
| Architecture | arm64 |
| Hostname | `pi-1.local` |
| Network | LAN only — not exposed to public internet |
