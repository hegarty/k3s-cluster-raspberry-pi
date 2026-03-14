#!/usr/bin/env bash
set -euo pipefail

if [[ "${RUN_CLUSTER_TESTS:-0}" != "1" ]]; then
  printf "Cluster smoke tests skipped (set RUN_CLUSTER_TESTS=1 to enable).\n"
  exit 0
fi

if ! command -v kubectl >/dev/null 2>&1; then
  printf "kubectl is not installed; cannot run cluster smoke tests.\n" >&2
  exit 1
fi

printf "Running cluster smoke tests...\n"

kubectl version --client >/dev/null
kubectl cluster-info >/dev/null
kubectl get nodes -o wide
kubectl get pods -A

printf "Cluster smoke tests passed.\n"
