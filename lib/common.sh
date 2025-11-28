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
    local lib; lib=$1
    copyAbis "$lib"
    copyBins "$lib"
    copyMeta "$lib"
}

# shellcheck disable=SC2001
# Use the locally built 0.31.1 dapp, regardless of PATH
dapp0_31_1="/home/tomo/dev/makerdao/fork/dapptools/result/bin/dapp"

if [ ! -x "$dapp0_31_1" ]; then
    echo "Error: expected dapp at $dapp0_31_1 but it is missing or not executable." >&2
    echo "Rebuild it in ~/dev/makerdao/fork/dapptools with: nix-build -A dapp" >&2
    exit 1
fi
export dapp0_31_1

dappCreate() {
    set -e
    local lib="$1"
    local class="$2"

    # Prefer a normalized override tree if provided (e.g. /tmp/dapp-libs-fresh),
    # falling back to whatever DAPP_LIB the Nix scripts set.
    local run_lib="${DAPP_LIB_OVERRIDE:-$DAPP_LIB}"
    local run_dir="$run_lib/$lib"

    # Names to try with dapp create
    local fq_class="$class"
    local alt_class="src/$class.sol:$class"

    echo "DEBUG(dappCreate): DAPP_LIB='$run_lib' lib='$lib' class='$class' fq_class='$fq_class' alt_class='$alt_class' DAPP_OUT='$run_dir/out'" >&2

    ETH_NONCE="$(cat "$NONCE_TMP_FILE")"

    # 1) Try plain class name
    if DAPP_OUT="$run_dir/out" DAPP_SRC="$run_dir/src" ETH_NONCE="$ETH_NONCE" \
        "$dapp0_31_1" create "$fq_class" "${@:3}"
    then
        :
    # 2) Try src/Foo.sol:Foo style
    elif DAPP_OUT="$run_dir/out" DAPP_SRC="$run_dir/src" ETH_NONCE="$ETH_NONCE" \
        "$dapp0_31_1" create "$alt_class" "${@:3}"
    then
        :
    else
        # 3) Last resort: read a matching contract key from dapp.sol.json
        local json="$run_dir/out/dapp.sol.json"
        if [ -f "$json" ]; then
            local key
            key="$(
                jq -r --arg want "$class" '
                  .contracts
                  | keys[]
                  | select( (.|split(":")|last) == $want )
                ' "$json" 2>/dev/null || true
            )"

            if [ -n "$key" ]; then
                echo "WARN(dappCreate): '$class' not found, retrying with contract key '$key' from $json" >&2
                if ! DAPP_OUT="$run_dir/out" DAPP_SRC="$run_dir/src" ETH_NONCE="$ETH_NONCE" \
                     "$dapp0_31_1" create "$key" "${@:3}"
                then
                    echo "ERROR(dappCreate): create failed even with contract key '$key'" >&2
                    return 1
                fi
            else
                echo "ERROR(dappCreate): class '$class' not found and no matching contract key in $json" >&2
                return 1
            fi
        else
            echo "ERROR(dappCreate): class '$class' not found and $json is missing" >&2
            return 1
        fi
    fi

    echo $((ETH_NONCE + 1)) > "$NONCE_TMP_FILE"
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
