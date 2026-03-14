# Initialization Objective

Provision a single-node k3s cluster on Raspberry Pi 5 (8GB).

## Required Outcome

- k3s server installed
- Node in Ready state
- No manual configuration
- Configuration managed via Ansible
- Repository reflects all changes

## Constraints

- Do not modify test files
- Do not perform manual kubectl changes
- All cluster configuration must originate from playbooks
- Must pass all tests in /tests

---

## Prerequisites

### Local machine (macOS)

| Tool | Required version | Check | Install if missing |
|------|-----------------|-------|--------------------|
| Homebrew | any | `brew --version` | `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"` |
| Ansible | >= 8 (core >= 2.15) | `ansible --version` | `brew install ansible` |
| Python 3 | >= 3.10 | `python3 --version` | bundled with Ansible via Homebrew |
| kubectl | any | `kubectl version --client` | `brew install kubectl` |
| SSH key | ed25519 at `~/.ssh/id_ed25519` | `ls ~/.ssh/id_ed25519` | `ssh-keygen -t ed25519 -C "your@email"` |

### SSH config (`~/.ssh/config`)

The following entry must be present so that Ansible and Make targets resolve the node:

```
Host rpi-1
    HostName pi-1.local
    User terence
    IdentityFile ~/.ssh/id_ed25519
```

Check: `ssh rpi-1 "echo ok"`

### Target node (pi-1.local)

| Requirement | Check | Notes |
|-------------|-------|-------|
| SSH accessible | `ssh rpi-1 "echo ok"` | Must succeed without password prompt |
| Passwordless sudo | `ssh rpi-1 "sudo -n true && echo ok"` | Required for Ansible become tasks |
| Python 3 present | `ssh rpi-1 "python3 --version"` | Debian 13 ships Python 3.13 |
| mDNS resolving | `ping -c1 pi-1.local` | Must resolve on LAN |

---

## Prerequisite Check Script

Run this before executing the plan to confirm all prerequisites are met:

```bash
#!/usr/bin/env bash
set -euo pipefail
PASS=0; FAIL=0

check() {
  local label="$1"; shift
  if "$@" &>/dev/null; then
    printf "  [OK]  %s\n" "$label"
    ((PASS++))
  else
    printf "  [FAIL] %s\n" "$label" >&2
    ((FAIL++))
  fi
}

echo "=== Local prerequisites ==="
check "Homebrew"          brew --version
check "Ansible"           ansible --version
check "Python 3"          python3 --version
check "kubectl"           kubectl version --client
check "SSH key exists"    test -f ~/.ssh/id_ed25519
check "SSH config: rpi-1" grep -q "Host rpi-1" ~/.ssh/config

echo ""
echo "=== Node prerequisites ==="
check "SSH connectivity"  ssh -o ConnectTimeout=5 rpi-1 "echo ok"
check "Passwordless sudo" ssh rpi-1 "sudo -n true"
check "Python 3 on node"  ssh rpi-1 "python3 --version"
check "mDNS resolves"     ping -c1 -W2 pi-1.local

echo ""
printf "Result: %d passed, %d failed\n" "$PASS" "$FAIL"
[[ $FAIL -eq 0 ]]
```

Save as `scripts/check-prereqs.sh` and run with `bash scripts/check-prereqs.sh`.

---

## Installation: Ansible (if missing)

```bash
brew install ansible
ansible --version   # expect: ansible [core 2.x.x]
```

Verify Ansible can reach the node:

```bash
ansible k3s_server -i inventory/hosts.yml -m ping
# expected: pi-1.local | SUCCESS => {"ping": "pong"}
```

## Installation: kubectl (if missing)

```bash
brew install kubectl
kubectl version --client
```

## SSH key setup (if missing)

```bash
ssh-keygen -t ed25519 -C "your@email"
ssh-copy-id -i ~/.ssh/id_ed25519.pub terence@pi-1.local
ssh rpi-1 "echo ok"
```

## Passwordless sudo on node (if missing)

```bash
ssh rpi-1 "echo 'terence ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/terence"
ssh rpi-1 "sudo -n true && echo ok"
```

---

## Execution

Once all prerequisites pass:

### Step 1 — Install k3s

```bash
make k3s-install
```

This runs in order:
1. `ansible-playbook -i inventory/hosts.yml playbooks/bootstrap.yml` — configures the OS (cgroups, swap, kernel modules)
2. `ansible-playbook -i inventory/hosts.yml playbooks/k3s_server.yml` — installs and starts k3s, waits for node Ready

The node will reboot automatically during bootstrap if kernel cmdline changes are needed. The playbook reconnects after reboot before continuing.

### Step 2 — Sync kubeconfig

```bash
make kubeconfig-sync
```

Copies `/etc/rancher/k3s/k3s.yaml` from the node, rewrites the server address to `pi-1.local`, and merges it into `~/.kube/config`.

### Step 3 — Validate cluster readiness

```bash
kubectl get nodes
```

Expected output:

```
NAME        STATUS   ROLES                  AGE   VERSION
pi-1.local  Ready    control-plane,master   Xm    v1.29.x+k3s1
```

```bash
kubectl get pods -A
```

All system pods (`coredns`, `traefik`, `local-path-provisioner`, `metrics-server`) should be `Running`.
