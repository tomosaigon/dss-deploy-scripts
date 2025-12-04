#!/usr/bin/env bash
# Run from repo root
set -euo pipefail

: "${TESTNET_HOST:=localhost}"
: "${TESTNET_PORT:=8545}"

# Default keystore location for the local testchain
: "${KEYSTORE_PATH:="$HOME/.dapp/testnet/$TESTNET_PORT/keystore"}"
export TESTNET_HOST TESTNET_PORT KEYSTORE_PATH
mkdir -p "$KEYSTORE_PATH"


cd "$(dirname "${BASH_SOURCE[0]}")/.."

########################################
# 1) Wire up ETH_* + geth for testchain
########################################
setup-env testchain || echo "WARN: setup-env testchain returned non-zero (\$?) but continuing"

########################################
# 2) Local dss-deploy environment
########################################
export BIN_DIR="$PWD/bin"
export LIB_DIR="$PWD/lib"
export LIBEXEC_DIR="$PWD/libexec"
export OUT_DIR="$PWD/out"
mkdir -p "$OUT_DIR"

# Our local prebuilt contracts (dss, dss-chain-log, etc.)
LOCAL_DAPP_LIB="$BIN_DIR/contracts"

# Try to discover the Nix-store DAPP_LIB used by the packaged dss-deploy
WRAPPER_PATH="$(command -v dss-deploy || true)"
if [[ -n "${WRAPPER_PATH:-}" ]] && grep -q "DAPP_LIB='" "$WRAPPER_PATH"; then
  NIX_DAPP_LIB="$(
    grep "DAPP_LIB='" "$WRAPPER_PATH" \
      | sed "s/.*DAPP_LIB='\(.*\)'.*/\1/"
  )"
  # Prefer local contracts, but keep the Nix store as a fallback
  export DAPP_LIB="$LOCAL_DAPP_LIB:$NIX_DAPP_LIB"
else
  # No wrapper found; just use local contracts
  export DAPP_LIB="$LOCAL_DAPP_LIB"
fi

export DAPP_SKIP_BUILD='yes'

echo "Using BIN_DIR=$BIN_DIR"
echo "Using LIB_DIR=$LIB_DIR"
echo "Using OUT_DIR=$OUT_DIR"
echo "Using DAPP_LIB=$DAPP_LIB"

########################################
# 3) Show local ChainLog artifact (for sanity)
########################################
CHAINLOG_JSON="$LOCAL_DAPP_LIB/dss-chain-log/dapp.sol.json"
if [[ -f "$CHAINLOG_JSON" ]]; then
  # CHAINLOG_KEY="$(
  #   jq -r '.contracts | keys[] | select(endswith(":ChainLog"))' \
  #     "$CHAINLOG_JSON" | head -n1 || true
  # )"
  CHAINLOG_KEY=$(
    jq -r '.contracts | keys[] | select(test("ChainLog"))' \
      "$BIN_DIR/contracts/dss-chain-log/dapp.sol.json"
  )
  if [[ -n "$CHAINLOG_KEY" && "$CHAINLOG_KEY" != "null" ]]; then
    echo "Local ChainLog artifact key: $CHAINLOG_KEY"
  else
    echo "WARN: No *:ChainLog key found in $CHAINLOG_JSON"
  fi
else
  echo "WARN: No local ChainLog JSON at $CHAINLOG_JSON"
fi

########################################
# 4) Load local common.sh (repo version)
########################################
# shellcheck source=/dev/null
source "$LIB_DIR/common.sh"

########################################
# 5) Point to local testchain config
########################################
export CONFIG="$PWD/config/testchain.json"

echo "Using CONFIG=$CONFIG"

########################################
# 6) Run the deploy
########################################
set +e
bash "$BIN_DIR/dss-deploy" testchain
STATUS=$?
set -e 2>/dev/null || true

echo "dss-deploy exit code: $STATUS"

echo "=== DEPLOY LOG (tail) ==="
grep 'DEPLOYMENT COMPLETED' "$OUT_DIR/dss-testchain.log" || echo "No completion line found"
tail -n 40 "$OUT_DIR/dss-testchain.log" || echo "No log file yet"

exit "$STATUS"