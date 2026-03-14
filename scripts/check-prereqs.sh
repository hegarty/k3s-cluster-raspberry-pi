#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0

check() {
  local label="$1"; shift
  if "$@" &>/dev/null; then
    printf "  [OK]   %s\n" "$label"
    ((PASS++)) || true
  else
    printf "  [FAIL] %s\n" "$label" >&2
    ((FAIL++)) || true
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
