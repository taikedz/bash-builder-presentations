#!/usr/bin/env bash

set -euo pipefail

DEFAULT_PORTS=(80 8080 25)

readonly ERR_no_mode=10
readonly ERR_no_error_code=101
readonly ERR_NaN=102
readonly ERR_bad_ports=103

function printhelp() {
    cat <<EOHELP
    portplug.sh [PORTS] Usage:ehlp

Prevent known insecure ports from being used.

By default: 80, 8080, 25

If PORTS are specified, uses those instead of the default set.

e.g.

  portplug.sh 80 8080 21 25

EOHELP
}

function die() {
    local code="${1:-}"; shift ||
        die $ERR_no_error_code "No code supplied"
    [[ "$code" =~ ^[0-9]+$ ]] ||
        die $ERR_NaN "Bad code supplied [$code] "\
          "while processing message '$*'"

    echo "$*" >&2
    exit "$code"
}

function setmode() {
    mode="$1"; shift

    declare -n ports
    ports="$1"; shift

    for port in "${ports[@]}"; do
        ufw "${mode[@]}" "${port[@]}"
    done
}

function main() {
    if [[ "$*" =~ --help ]]; then
        printhelp
    fi

    local mode="${1:-}"; shift ||
        die $ERR_no_mode "Please specify a mode ('on' or 'off')"
    local ports=("${DEFAULT_PORTS[@]}")

    if [[ "$mode" = on ]]; then
        mode=(deny)
    elif [[ "$mode" = off ]]; then
        mode=(delete deny)
    else
        die $ERR_no_mode "Invalid mode passed '$mode'"
    fi

    if [[ -n "$*" ]]; then ports=("$@") ; fi

    echo "Processing ${ports[*]}"
    setmode "$mode" ports || {
        printhelp
        die $ERR_bad_ports "Could not process ${ports[*]}"
    }
}

main "$@"
