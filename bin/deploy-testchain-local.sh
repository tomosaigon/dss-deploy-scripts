#!/usr/bin/env bash
# Don't use `set -e` with these legacy scripts, it will kill us on benign failures.
set -o pipefail

# Run from repo root
cd "$(dirname "${BASH_SOURCE[0]}")/.."

########################################
# 1) Wire up ETH_* + geth for testchain
########################################
# This prints the "Using RPC URL..." and DAPPTOOLS VARIABLES banner.
setup-env testchain || echo "WARN: setup-env testchain returned non-zero ($?) but continuing"

########################################
# 2) Local dss-deploy environment
########################################
export BIN_DIR="$PWD/bin"
export LIB_DIR="$PWD/lib"
export LIBEXEC_DIR="$PWD/libexec"
export OUT_DIR="$PWD/out"
mkdir -p "$OUT_DIR"

# This Nix store path may change when the package is rebuilt
: "${DAPP_LIB_OVERRIDE:=/nix/store/skkwbmqmcc0bdxg5z9228l2bsffklvbs-dss-deploy-scripts-solidity-packages/dapp}"
export DAPP_LIB_OVERRIDE

# 3) Load local common.sh (patched version)
source "$LIB_DIR/common.sh"

# 4) Point to local testchain config
export CONFIG="$PWD/config/testchain.json"

echo "Using BIN_DIR=$BIN_DIR"
echo "Using LIB_DIR=$LIB_DIR"
echo "Using OUT_DIR=$OUT_DIR"
echo "Using CONFIG=$CONFIG"
echo "Using DAPP_LIB_OVERRIDE=$DAPP_LIB_OVERRIDE"

########################################
# 5) Run the deploy (no -e here!)
########################################
set +e
bash "$BIN_DIR/dss-deploy" testchain
STATUS=$?
set -e 2>/dev/null || true   # harmless if -e was never on

echo "dss-deploy exit code: $STATUS"

echo "=== DEPLOY LOG (tail) ==="
grep 'DEPLOYMENT COMPLETED' "$OUT_DIR/dss-testchain.log" || echo "No completion line found"
tail -n 40 "$OUT_DIR/dss-testchain.log" || echo "No log file yet"

exit "$STATUS"