#!/usr/bin/env bash

open_tab() {
    open_view --tab "$@"
}

open_window() {
    open_view --window "$@"
}

open_view() {
    local mode="$1"; shift
    local dest="$1"; shift

    local commands
    commands=(bash)
    if [[ -n "$*" ]]; then
        commands=("$@")
    fi

    mate-terminal "$mode" --maximize -e "bash -c 'cd $dest; ${commands[@]}'"
}

tk="${1:-}"; shift || {
    echo "Specify my github.com/account folder path"
}

# Open last window to use first

firefox https://github.com/taikedz/bash-builder/tree/master/docs

# Second-to-last

open_window "$tk/bash-libs"
open_tab "$tk/alpacka"
open_tab "$tk/git-shortcuts"
open_tab "$tk/webserver.sh"

# First window

open_window "$tk/our-pxe" "vim bin/remaster.sh"
open_tab "$tk/remaster.sh" "vim remaster.sh"

open_tab "$tk/bash-builder-presentations/talks/2019-03-13-techmeetup/scripts" 'vim *-portplug.sh' #'vim 01-portplug.sh  02-portplug.sh  03-portplug.sh  04-portplug.sh  05-portplug.sh'
