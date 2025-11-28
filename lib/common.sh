#!/usr/bin/env bash

#  Copyright (C) 2019-2021 Maker Ecosystem Growth Holdings, INC.

#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU Affero General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.

#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU Affero General Public License for more details.

#  You should have received a copy of the GNU Affero General Public License
#  along with this program.  If not, see <https://www.gnu.org/licenses/>.

# Set fail flags
set -eo pipefail

DAPP_LIB=${DAPP_LIB:-$BIN_DIR/contracts}

export NONCE_TMP_FILE
clean() {
    test -f "$NONCE_TMP_FILE" && rm "$NONCE_TMP_FILE"
}
if [[ -z "$NONCE_TMP_FILE" && -n "$ETH_FROM" ]]; then
    nonce=$(seth nonce "$ETH_FROM")
    NONCE_TMP_FILE=$(mktemp)
    echo "$nonce" > "$NONCE_TMP_FILE"
    trap clean EXIT
fi

# arg: the name of the config file to write
writeConfigFor() {
    # Clean out directory
    rm -rf "$OUT_DIR" && mkdir "$OUT_DIR"
    # If config file is passed via param used that one
    if [[ -n "$CONFIG" ]]; then
        cp "$CONFIG" "$CONFIG_FILE"
    # If environment variable exists bring the values from there
    elif [[ -n "$DDS_CONFIG_VALUES" ]]; then
        echo "$DDS_CONFIG_VALUES" > "$CONFIG_FILE"
    # otherwise use the default config file
    else
        cp "$CONFIG_DIR/$1.json" "$CONFIG_FILE"
    fi
}

# loads addresses as key-value pairs from $ADDRESSES_FILE and exports them as
# environment variables.
loadAddresses() {
    local keys

    keys=$(jq -r "keys_unsorted[]" "$ADDRESSES_FILE")
    for KEY in $keys; do
        VALUE=$(jq -r ".$KEY" "$ADDRESSES_FILE")
        export "$KEY"="$VALUE"
    done
}

addAddresses() {
    result=$(jq -s add "$ADDRESSES_FILE" /dev/stdin)
    printf %s "$result" > "$ADDRESSES_FILE"
}

copyAbis() {
    local lib; lib=$1
    local DIR; DIR="$OUT_DIR/abi/$lib"
    mkdir -p "$DIR"
    find "$DAPP_LIB/$lib/out" \
        -name "*.abi" ! -name "*Test.abi" ! -name "*Like.abi" ! -name "*DSNote.abi" ! -name "*FakeUser.abi" ! -name "*Hevm.abi" \
        -exec cp -f {} "$DIR" \;
}

copyBins() {
    local lib; lib=$1
    local DIR; DIR="$OUT_DIR/bin/$lib"
    mkdir -p "$DIR"
    find "$DAPP_LIB/$lib/out" \
        -name "*.bin" ! -name "*Test.bin" ! -name "*Like.bin" ! -name "*DSNote.bin" ! -name "*FakeUser.bin" ! -name "*Hevm.bin" \
        -exec cp -f {} "$DIR" \;
    find "$DAPP_LIB/$lib/out" \
        -name "*.bin-runtime" ! -name "*Test.bin-runtime" ! -name "*Like.bin-runtime" ! -name "*DSNote.bin-runtime" ! -name "*FakeUser.bin-runtime" ! -name "*Hevm.bin-runtime"  \
        -exec cp -f {} "$DIR" \;
}

copyMeta() {
    local lib; lib=$1
    local DIR; DIR="$OUT_DIR/meta/$lib"
    mkdir -p "$DIR"
    find "$DAPP_LIB/$lib/out" \
        -name "*.metadata" ! -name "*Test.metadata" ! -name "*Like.metadata" ! -name "*DSNote.metadata" ! -name "*FakeUser.metadata" ! -name "*Hevm.metadata"  \
        -exec cp -f {} "$DIR" \;
}

copy() {
    # NOTE: do NOT use `set -e` in here; callers may be running with `-e`.
    local lib="$1"

    local srcdir=""

    # 1) Original layout: repo-built artifacts
    if [ -d "$BIN_DIR/contracts/$lib/out" ]; then
        srcdir="$BIN_DIR/contracts/$lib/out"

    # 2) Nix solidity-packages override
    elif [ -n "${DAPP_LIB_OVERRIDE:-}" ] && [ -d "$DAPP_LIB_OVERRIDE/$lib/out" ]; then
        srcdir="$DAPP_LIB_OVERRIDE/$lib/out"

    # 3) Legacy DAPP_LIB tree
    elif [ -n "${DAPP_LIB:-}" ] && [ -d "$DAPP_LIB/$lib/out" ]; then
        srcdir="$DAPP_LIB/$lib/out"
    else
        echo "WARN(copy): no artifact directory found for lib '$lib'" >&2
        echo "  looked for:" >&2
        echo "    $BIN_DIR/contracts/$lib/out" >&2
        if [ -n "${DAPP_LIB_OVERRIDE:-}" ]; then
            echo "    $DAPP_LIB_OVERRIDE/$lib/out" >&2
        fi
        if [ -n "${DAPP_LIB:-}" ]; then
            echo "    $DAPP_LIB/$lib/out" >&2
        fi
        # Don't fail the whole deploy just because we couldn't copy artifacts
        return 0
    fi

    # 4) Copy into OUT_DIR mirror
    local dest="$OUT_DIR/contracts/$lib"
    mkdir -p "$dest"
    cp -R "$srcdir"/. "$dest"/

    echo "DEBUG(copy): copied artifacts for '$lib' from '$srcdir' to '$dest'" >&2
}

# shellcheck disable=SC2001
# Use the locally built 0.31.1 dapp, regardless of PATH
# dapp0_31_1="/home/tomo/dev/makerdao/fork/dapptools/result/bin/dapp"

# if [ ! -x "$dapp0_31_1" ]; then
#     echo "Error: expected dapp at $dapp0_31_1 but it is missing or not executable." >&2
#     echo "Rebuild it in ~/dev/makerdao/fork/dapptools with: nix-build -A dapp" >&2
#     exit 1
# fi
# export dapp0_31_1

dappCreate() {
    # IMPORTANT: do NOT use `set -e` in here; callers may be running with `-e`
    local lib="$1"
    local class="$2"

    ############################################################
    # 1) Decide which library tree to use
    ############################################################
    local base_lib=""

    if [ -n "${DAPP_LIB_OVERRIDE:-}" ]; then
        base_lib="$DAPP_LIB_OVERRIDE/$lib"
    elif [ -n "${DAPP_LIB:-}" ]; then
        base_lib="$DAPP_LIB/$lib"
    else
        echo "ERROR(dappCreate): neither DAPP_LIB_OVERRIDE nor DAPP_LIB is set" >&2
        return 1
    fi

    ############################################################
    # 2) Locate dapp.sol.json in that tree
    ############################################################
    local json=""

    # Common simple case: $base_lib/out/dapp.sol.json
    if [ -f "$base_lib/out/dapp.sol.json" ]; then
        json="$base_lib/out/dapp.sol.json"
    else
        # More defensive: look for any */out/dapp.sol.json under base_lib
        json="$(find "$base_lib" -path '*/out/dapp.sol.json' -print -quit 2>/dev/null || true)"
    fi

    if [ -z "$json" ] || [ ! -f "$json" ]; then
        echo "ERROR(dappCreate): artifact JSON not found for lib '$lib'" >&2
        echo "  searched under: $base_lib" >&2
        echo "  DAPP_LIB_OVERRIDE=${DAPP_LIB_OVERRIDE:-<unset>}" >&2
        echo "  DAPP_LIB=${DAPP_LIB:-<unset>}" >&2
        return 1
    fi

    ############################################################
    # 3) Find the contract key whose suffix matches $class
    ############################################################
    local key
    key="$(
        jq -r --arg want "$class" '
          .contracts
          | keys[]
          | select( (.|split(":")|last) == $want )
        ' "$json" 2>/dev/null || true
    )"

    if [ -z "$key" ]; then
        echo "ERROR(dappCreate): no contract key ending with \"$class\" in $json" >&2
        return 1
    fi

    ############################################################
    # 4) Extract bytecode
    ############################################################
    local bytecode
    bytecode="$(jq -r --arg k "$key" '.contracts[$k].bin' "$json")"
    if [ -z "$bytecode" ] || [ "$bytecode" = "null" ]; then
        echo "ERROR(dappCreate): empty bytecode for key \"$key\" in $json" >&2
        return 1
    fi

    case "$bytecode" in
        0x*) : ;;
        *) bytecode="0x$bytecode" ;;
    esac

    ############################################################
    # 5) Use NONCE_TMP_FILE for deterministic nonces
    ############################################################
    local nonce
    nonce="$(cat "$NONCE_TMP_FILE")"

    echo "DEBUG(dappCreate): lib='$lib' class='$class' key='$key' json='$json' nonce='$nonce'" >&2

    ############################################################
    # 6) Send the create tx and capture output
    ############################################################
    local raw tx receipt addr
    raw="$(ETH_NONCE="$nonce" seth send --gas "$ETH_GAS" --create "$bytecode" 2>&1)"
    printf '%s\n' "$raw" >&2  # keep all chatter on stderr

    # 2) Extract the 32-byte tx hash from the output.
    #    Works with both:
    #      - verbose "seth-send: Published transaction ..." style
    #      - minimal output where the tx hash is printed alone.
    tx="$(
      printf '%s\n' "$raw" \
        | grep -o '0x[0-9a-fA-F]\{64\}' \
        | tail -n1
    )"

    if [ -z "$tx" ]; then
        echo "ERROR(dappCreate): failed to parse tx hash from seth output" >&2
        return 1
    fi

    ############################################################
    # 7) Read receipt and pull contractAddress
    ############################################################
    receipt="$(seth receipt "$tx" 2>&1 | grep -v '^seth-rpc:')"
    addr="$(
      printf '%s\n' "$receipt" \
        | awk '$1=="contractAddress"{print $2}'
    )"

    if [ -z "$addr" ] || [ "$addr" = "null" ]; then
        echo "ERROR(dappCreate): failed to parse contractAddress from receipt for tx $tx" >&2
        printf 'Receipt was:\n%s\n' "$receipt" >&2
        return 1
    fi

    # Print the address on stdout – other scripts depend on this
    echo "$addr"

    ############################################################
    # 8) Increment nonce and copy artifacts
    ############################################################
    echo $((nonce + 1)) > "$NONCE_TMP_FILE"
    copy "$lib"
}

sethSend() {
    set -e
    echo "seth send $*"
    ETH_NONCE=$(cat "$NONCE_TMP_FILE")
    ETH_NONCE="$ETH_NONCE" seth send "$@"
    echo $((ETH_NONCE + 1)) > "$NONCE_TMP_FILE"
    echo ""
}

join() {
    local IFS=","
    echo "$*"
}

GREEN='\033[0;32m'
NC='\033[0m' # No Color

log() {
    printf '%b\n' "${GREEN}${1}${NC}"
    echo ""
}

logAddr() {
    sethSend "$CHANGELOG" 'setAddress(bytes32,address)' "$(seth --to-bytes32 "$(seth --from-ascii "$1")")" "$2"
    printf '%b\n' "${GREEN}${1}=${2}${NC}"
    echo ""
}

toUpper() {
    echo "$1" | tr '[:lower:]' '[:upper:]'
}

toLower() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

# Start verbose output
# set -x

# Set exported variables
export ETH_GAS=7000000
unset SOLC_FLAGS

export OUT_DIR=${OUT_DIR:-$PWD/out}
ADDRESSES_FILE="$OUT_DIR/addresses.json"
export CONFIG_FILE="${OUT_DIR}/config.json"
