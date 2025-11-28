#!/usr/bin/env bash
set -eo pipefail

# Run from repo root
cd "$(dirname "${BASH_SOURCE[0]}")/.."

# 0) Ensure we’re in a dss-deploy nix-shell-ish environment
# (Optional) You can uncomment this if you *want* it to fail loudly when not in nix-shell:
# : "${IN_NIX_SHELL:?This script expects to be run from inside nix-shell}"

# 1) Environment for the bash-based dss-deploy
export BIN_DIR="$PWD/bin"
export LIB_DIR="$PWD/lib"
export LIBEXEC_DIR="$PWD/libexec"
export OUT_DIR="$PWD/out"
mkdir -p "$OUT_DIR"

# 2) Dapp libs override (update this path if Nix rebuilds the store path)
: "${DAPP_LIB_OVERRIDE:=/nix/store/skkwbmqmcc0bdxg5z9228l2bsffklvbs-dss-deploy-scripts-solidity-packages/dapp}"
export DAPP_LIB_OVERRIDE

# 3) Load patched common.sh (this wires dapp0_31_1 + dappCreate)
#    common.sh expects ETH_FROM / ETH_RPC_URL etc., so run setup-env first.
source "$LIB_DIR/common.sh"

# 4) Default config for testchain
: "${CONFIG_DIR:=$PWD/config}"
CONFIG="${CONFIG:-$PWD/config/testchain.json}"

echo "Using CONFIG=$CONFIG"
echo "Using BIN_DIR=$BIN_DIR"
echo "Using DAPP_LIB_OVERRIDE=$DAPP_LIB_OVERRIDE"
echo "Using OUT_DIR=$OUT_DIR"

# 5) Actually run the deploy
CONFIG="$CONFIG" bash "$BIN_DIR/dss-deploy" testchain
STATUS=$?

echo "dss-deploy exit code: $STATUS"

echo "=== tail of out/dss-testchain.log ==="
tail -n 40 "$OUT_DIR/dss-testchain.log" || echo "No log file yet"

exit "$STATUS"