### Server hovercraft Usage:help
# add LIBS -- add extra libs
# run -- run command in virtualenv environment
# serve PRESENTATION -- serve a presentation from directory
###/doc

#%include std/safe.sh
#%include std/out.sh
#%include std/autohelp.sh
#%include std/syntax-extensions.sh
#%include std/bincheck.sh
#%include std/varify.sh

#%include app/pyvenv.sh

$%function serve-presentation(mainfile) {
    mkdir -p presentation
    local pdir="$(mktemp -d "presentation/$(varify:fil "$mainfile")-XXXX")"
    hovercraft "$mainfile" "$pdir"
    local runtime
    runtime="$(bincheck:get sensible-browser firefox chromium chrome gnome-www-browser epiphany x-www-browser www-browser)"

    "$runtime" "$pdir/index.html"
}

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
        serve-presentation "$@" ;;
    *)
        autohelp:print
        out:fail "Unknown action";;
    esac
}

main "$@"
