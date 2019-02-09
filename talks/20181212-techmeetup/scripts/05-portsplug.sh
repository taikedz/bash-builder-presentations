#!/usr/bin/env bash

#%include std/out.sh
#%include std/autohelp.sh
#%include std/syntax-extensions.sh

#%include 05-help.sh
#%include 05-ports.sh

set -euo pipefail

DEFAULT_PORTS=(80 8080 25)

readonly ERR_no_mode=10
readonly ERR_no_error_code=101
readonly ERR_NaN=102
readonly ERR_bad_ports=103

$%function pplug:main(?mode) {
    autohelp:check "$mode" "$@"
    local ports
    useports ports "$@"

    case "$mode"
    on)
        mode=(deny) ;;
    off)
        mode=(delete deny) ;;
    *)
        autohelp:print
        out:fail $ERR_no_mode "Invalid mode passed '$mode'" ;;
    esac

    echo "Processing ${ports[*]}"

    pplug:ports:applymode "$mode" ports ||
        out:fail $ERR_bad_ports "Could not process ${ports[*]}"
}

pplug:main "$@"

