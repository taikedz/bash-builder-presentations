#!/usr/bin/env bash

### Hovercraft launcher Usage:help
# Simple script to build and run a hovercraft presentation using a python virtual environment
#
# hover.sh serve MAINFILE
#   Serve the target RST file as a hovercraft presentation
#
# hover.sh add PYTHON-PACKAGE ...
#   Add python packages to the virtual environment
#
# hover.sh run COMMAND ...
#   Run a command with the virtual environment activated
###/doc

#%include std/autohelp.sh
#%include std/out.sh
#%include std/syntax-extensions.sh

#%include app/pyvenv.sh
#%include app/hovercraft.sh

$%function main(?action) {
    autohelp:check "$@" "$action"

    out:info "Ensuring hovercraft ..."
    pyvenv:ensure hovercraft-venv python3

    out:info "Activating ..."
    pyvenv:activate hovercraft-venv

    case "$action" in
    add)
        pyvenv:add "$@" ;;
    run)
        "$@" ;;
    serve)
        hovercraft:serve "$@" ;;
    *)
        autohelp:print
        out:fail "Unknown action";;
    esac
}

main "$@"
