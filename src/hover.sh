#&include std/autohelp.sh
#&include std/out.sh
#%include std/syntax-extensions.sh

#%include app/pyvenv.sh
#%include app/hovercraft.sh

$%function main(?action) {
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
