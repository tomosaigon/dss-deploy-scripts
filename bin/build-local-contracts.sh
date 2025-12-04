#!/usr/bin/env bash
# Build local Solidity packages (dss, dss-chain-log, etc.) into bin/contracts
set -euo pipefail

# Run from repo root
cd "$(dirname "${BASH_SOURCE[0]}")/.."

OUT_ROOT="$PWD/bin/contracts"
mkdir -p "$OUT_ROOT"

build_one() {
  local name="$1"
  local src="$2"

  local dest="$OUT_ROOT/$name"

  echo
  echo "---- Building package '$name' from '$src'"
  echo "     -> $dest"

  (
    cd "$src"

    # Clean any previous dapp build artifacts for this package
    rm -rf out || true
    dapp clean || true

    # Clean destination and build with a custom DAPP_OUT
    rm -rf "$dest"
    mkdir -p "$dest"

    DAPP_OUT="$dest" dapp build
  )
}

# 1) DSS from ../dss (uses your DAPP_REMAPPINGS from the current shell)
build_one dss "$PWD/../dss"

# 2) ChainLog from ../dss-chain-log
#    For ChainLog we usually *want* dapp's own remapping detection,
#    so we override the env locally in this subshell.
(
  unset DAPP_REMAPPINGS
  unset DAPP_AUTO_DETECT_REMAPPINGS
  export DAPP_AUTO_DETECT_REMAPPINGS=true

  build_one dss-chain-log "$PWD/../dss-chain-log"
)

echo
echo "===> Done. Contracts are under $OUT_ROOT"
find "$OUT_ROOT" -maxdepth 2 -mindepth 1 -type d -print || true