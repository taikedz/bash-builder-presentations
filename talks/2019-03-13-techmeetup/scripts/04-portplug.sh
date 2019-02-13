#!/usr/bin/env bash

### portplug.sh [PORTS] Usage:help
# 
# Prevent known insecure ports from being used.
#
# By default: 80, 8080, 25
#
# If PORTS are specified, uses those instead of the default set.
#
# e.g.
#
#   portplug.sh 80 8080 21 25
#
###/doc

#%include std/out.sh
#%include std/autohelp.sh
#%include std/syntax-extensions.sh

set -euo pipefail

DEFAULT_PORTS=(80 8080 25)

readonly ERR_no_mode=10
readonly ERR_no_error_code=101
readonly ERR_NaN=102
readonly ERR_bad_ports=103

$%function applymode(*p_action *p_ports) {
    local port

    for port in "${p_ports[@]}"; do
        ufw "${p_action[@]}" "$port"
    done
}

$%function useports(*p_portsvar) {
    if [[ -n "$*" ]]; then
        p_portsvar=("$@")
    else
        p_portsvar=("${DEFAULT_PORTS[@]}")
    fi
}

$%function main(mode) {
    local ports ufw_action
    useports ports "$@"

    case "$mode" in
    on)
        ufw_action=(deny) ;;
    off)
        ufw_action=(delete deny) ;;
    *)
        autohelp:print
        out:fail $ERR_no_mode "Invalid mode passed '$mode'" ;;
    esac

    echo "Processing ${ports[*]}"

    applymode ufw_action ports ||
        out:fail $ERR_bad_ports "Could not process ${ports[*]}"
}

autohelp:check-or-null "$@"
main "$@"

