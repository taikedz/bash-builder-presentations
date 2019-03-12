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

##bash-libs: tty.sh @ 6e4f511f (2.1.4)

tty:is_ssh() {
    [[ -n "$SSH_TTY" ]] || [[ -n "$SSH_CLIENT" ]] || [[ "$SSH_CONNECTION" ]]
}

tty:is_pipe() {
    [[ ! -t 1 ]]
}

##bash-libs: colours.sh @ 6e4f511f (2.1.4)

### Colours for terminal Usage:bbuild
# A series of shorthand colour flags for use in outputs, and functions to set your own flags.
#
# Not all terminals support all colours or modifiers.
#
# Example:
# 	
# 	echo "${CRED}Some red text ${CBBLU} some blue text. $CDEF Some text in the terminal's default colour")
#
# Preconfigured colours available:
#
# CRED, CBRED, HLRED -- red, bright red, highlight red
# CGRN, CBGRN, HLGRN -- green, bright green, highlight green
# CYEL, CBYEL, HLYEL -- yellow, bright yellow, highlight yellow
# CBLU, CBBLU, HLBLU -- blue, bright blue, highlight blue
# CPUR, CBPUR, HLPUR -- purple, bright purple, highlight purple
# CTEA, CBTEA, HLTEA -- teal, bright teal, highlight teal
# CBLA, CBBLA, HLBLA -- black, bright red, highlight red
# CWHI, CBWHI, HLWHI -- white, bright red, highlight red
#
# Modifiers available:
#
# CBON - activate bright
# CDON - activate dim
# ULON - activate underline
# RVON - activate reverse (switch foreground and background)
# SKON - activate strikethrough
# 
# Resets available:
#
# CNORM -- turn off bright or dim, without affecting other modifiers
# ULOFF -- turn off highlighting
# RVOFF -- turn off inverse
# SKOFF -- turn off strikethrough
# HLOFF -- turn off highlight
#
# CDEF -- turn off all colours and modifiers(switches to the terminal default)
#
# Note that highlight and underline must be applied or re-applied after specifying a colour.
#
# If the session is detected as being in a pipe, colours will be turned off.
#   You can override this by calling `colours:check --color=always` at the start of your script
#
###/doc

### colours:check ARGS ... Usage:bbuild
#
# Check the args to see if there's a `--color=always` or `--color=never`
#   and reload the colours appropriately
#
#   main() {
#       colours:check "$@"
#
#       echo "${CGRN}Green only in tty or if --colours=always !${CDEF}"
#   }
#
#   main "$@"
#
###/doc
colours:check() {
    if [[ "$*" =~ --color=always ]]; then
        COLOURS_ON=true
    elif [[ "$*" =~ --color=never ]]; then
        COLOURS_ON=false
    fi

    colours:define
    return 0
}

### colours:set CODE Usage:bbuild
# Set an explicit colour code - e.g.
#
#   echo "$(colours:set "33;2")Dim yellow text${CDEF}"
#
# See SGR Colours definitions
#   <https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_(Select_Graphic_Rendition)_parameters>
###/doc
colours:set() {
    # We use `echo -e` here rather than directly embedding a binary character
    if [[ "$COLOURS_ON" = false ]]; then
        return 0
    else
        echo -e "\033[${1}m"
    fi
}

colours:define() {

    # Shorthand colours

    export CBLA="$(colours:set "30")"
    export CRED="$(colours:set "31")"
    export CGRN="$(colours:set "32")"
    export CYEL="$(colours:set "33")"
    export CBLU="$(colours:set "34")"
    export CPUR="$(colours:set "35")"
    export CTEA="$(colours:set "36")"
    export CWHI="$(colours:set "37")"

    export CBBLA="$(colours:set "1;30")"
    export CBRED="$(colours:set "1;31")"
    export CBGRN="$(colours:set "1;32")"
    export CBYEL="$(colours:set "1;33")"
    export CBBLU="$(colours:set "1;34")"
    export CBPUR="$(colours:set "1;35")"
    export CBTEA="$(colours:set "1;36")"
    export CBWHI="$(colours:set "1;37")"

    export HLBLA="$(colours:set "40")"
    export HLRED="$(colours:set "41")"
    export HLGRN="$(colours:set "42")"
    export HLYEL="$(colours:set "43")"
    export HLBLU="$(colours:set "44")"
    export HLPUR="$(colours:set "45")"
    export HLTEA="$(colours:set "46")"
    export HLWHI="$(colours:set "47")"

    # Modifiers
    
    export CBON="$(colours:set "1")"
    export CDON="$(colours:set "2")"
    export ULON="$(colours:set "4")"
    export RVON="$(colours:set "7")"
    export SKON="$(colours:set "9")"

    # Resets

    export CBNRM="$(colours:set "22")"
    export HLOFF="$(colours:set "49")"
    export ULOFF="$(colours:set "24")"
    export RVOFF="$(colours:set "27")"
    export SKOFF="$(colours:set "29")"

    export CDEF="$(colours:set "0")"

}

colours:auto() {
    if tty:is_pipe ; then
        COLOURS_ON=false
    else
        COLOURS_ON=true
    fi

    colours:define
    return 0
}

colours:auto

##bash-libs: out.sh @ 6e4f511f (2.1.4)

### Console output handlers Usage:bbuild
#
# Write data to console stderr using colouring
#
###/doc

### out:info MESSAGE Usage:bbuild
# print a green informational message to stderr
###/doc
function out:info {
    echo "$CGRN$*$CDEF" 1>&2
}

### out:warn MESSAGE Usage:bbuild
# print a yellow warning message to stderr
###/doc
function out:warn {
    echo "${CBYEL}WARN: $CYEL$*$CDEF" 1>&2
}

### out:defer MESSAGE Usage:bbuild
# Store a message in the output buffer for later use
###/doc
function out:defer {
    OUTPUT_BUFFER_defer[${#OUTPUT_BUFFER_defer[@]}]="$*"
}

# Internal
function out:buffer_initialize {
    OUTPUT_BUFFER_defer=(:)
}
out:buffer_initialize

### out:flush HANDLER ... Usage:bbuild
#
# Pass the output buffer to the command defined by HANDLER
# and empty the buffer
#
# Examples:
#
# 	out:flush echo -e
#
# 	out:flush out:warn
#
# (escaped newlines are added in the buffer, so `-e` option is
#  needed to process the escape sequences)
#
###/doc
function out:flush {
    [[ -n "$*" ]] || out:fail "Did not provide a command for buffered output\n\n${OUTPUT_BUFFER_defer[*]}"

    [[ "${#OUTPUT_BUFFER_defer[@]}" -gt 1 ]] || return 0

    for buffer_line in "${OUTPUT_BUFFER_defer[@]:1}"; do
        "$@" "$buffer_line"
    done

    out:buffer_initialize
}

### out:fail [CODE] MESSAGE Usage:bbuild
# print a red failure message to stderr and exit with CODE
# CODE must be a number
# if no code is specified, error code 127 is used
###/doc
function out:fail {
    local ERCODE=127
    local numpat='^[0-9]+$'

    if [[ "$1" =~ $numpat ]]; then
        ERCODE="$1"; shift || :
    fi

    echo "${CBRED}ERROR FAIL: $CRED$*$CDEF" 1>&2
    exit $ERCODE
}

### out:error MESSAGE Usage:bbuild
# print a red error message to stderr
#
# unlike out:fail, does not cause script exit
###/doc
function out:error {
    echo "${CBRED}ERROR: ${CRED}$*$CDEF" 1>&2
}

##bash-libs: syntax-extensions.sh @ 6e4f511f (2.1.4)

### Syntax Extensions Usage:syntax
#
# Syntax extensions for bash-builder.
#
# You will need to import this library if you use Bash Builder's extended syntax macros.
#
# You should not however use the functions directly, but the extended syntax instead.
#
##/doc

### syntax-extensions:use FUNCNAME ARGNAMES ... Usage:syntax
#
# Consume arguments into named global variables.
#
# If not enough argument values are found, the first named variable that failed to be assigned is printed as error
#
# ARGNAMES prefixed with '?' do not trigger an error
#
# Example:
#
#   #%include out.sh
#   #%include syntax-extensions.sh
#
#   get_parameters() {
#       . <(syntax-extensions:use get_parameters INFILE OUTFILE ?comment)
#
#       [[ -f "$INFILE" ]]  || out:fail "Input file '$INFILE' does not exist"
#       [[ -f "$OUTFILE" ]] || out:fail "Output file '$OUTFILE' does not exist"
#
#       [[ -z "$comment" ]] || echo "Note: $comment"
#   }
#
#   main() {
#       get_parameters "$@"
#
#       echo "$INFILE will be converted to $OUTFILE"
#   }
#
#   main "$@"
#
###/doc
syntax-extensions:use() {
    local argname arglist undef_f dec_scope argidx argone failmsg pos_ok
    
    dec_scope=""
    [[ "${SYNTAXLIB_scope:-}" = local ]] || dec_scope=g
    arglist=(:)
    argone=\"\${1:-}\"
    pos_ok=true
    
    for argname in "$@"; do
        [[ "$argname" != -- ]] || break
        [[ "$argname" =~ ^(\?|\*)?[0-9a-zA-Z_]+$ ]] || out:fail "Internal: Not a valid argument name '$argname'"

        arglist+=("$argname")
    done

    argidx=1
    while [[ "$argidx" -lt "${#arglist[@]}" ]]; do
        argname="${arglist[$argidx]}"
        failmsg="\"Internal: could not get '$argname' in function arguments\""
        posfailmsg="Internal: positional argument '$argname' encountered after optional argument(s)"

        if [[ "$argname" =~ ^\? ]]; then
            echo "$SYNTAXLIB_scope ${argname:1}=$argone; shift || :"
            pos_ok=false

        elif [[ "$argname" =~ ^\* ]]; then
            [[ "$pos_ok" != false ]] || out:fail "$posfailmsg"
            echo "[[ '${argname:1}' != \"$argone\" ]] || out:fail \"Internal: Local name [$argname] equals upstream [$argone]. Rename [$argname] (suggestion: [*p_${argname:1}])\""
            echo "declare -n${dec_scope} ${argname:1}=$argone; shift || out:fail $failmsg"

        else
            [[ "$pos_ok" != false ]] || out:fail "$posfailmsg"
            echo "$SYNTAXLIB_scope ${argname}=$argone; shift || out:fail $failmsg"
        fi

        argidx=$((argidx + 1))
    done
}


### syntax-extensions:use:local FUNCNAME ARGNAMES ... Usage:syntax
# 
# Enables syntax macro: function signatures
#   e.g. $%function func(var1 var2) { ... }
#
# Build with bbuild to leverage this function's use:
#
#   #%include out.sh
#   #%include syntax-extensions.sh
#
#   $%function person(name email) {
#       echo "$name <$email>"
#
#       # $1 and $2 have been consumed into $name and $email
#       # The rest remains available in $* :
#       
#       echo "Additional notes: $*"
#   }
#
#   person "Jo Smith" "jsmith@example.com" Some details
#
###/doc
syntax-extensions:use:local() {
    SYNTAXLIB_scope=local syntax-extensions:use "$@"
}

args:use:local() {
    syntax-extensions:use:local "$@"
}

##bash-libs: autohelp.sh @ 6e4f511f (2.1.4)

### Autohelp Usage:bbuild
#
# Autohelp provides some simple facilities for defining help as comments in your code.
# It provides several functions for printing specially formatted comment sections.
#
# Write your help as documentation comments in your script
#
# To output a named section from your script, or a file, call the
# `autohelp:print` function and it will print the help documentation
# in the current script, or specified file, to stdout
#
# A help comment looks like this:
#
#    ### <title> Usage:help
#    #
#    # <some content>
#    #
#    # end with "###/doc" on its own line (whitespaces before
#    # and after are OK)
#    #
#    ###/doc
#
# It can then be printed from the same script by simply calling
#
#   autohelp:print
#
# You can print a different section by specifying a different name
#
# 	autohelp:print section2
#
# > This would print a section defined in this way:
#
# 	### Some title Usage:section2
# 	# <some content>
# 	###/doc
#
# You can set a different comment character by setting the 'HELPCHAR' environment variable.
# Typically, you might want to print comments you set in a INI config file, for example
#
# 	HELPCHAR=";" autohelp:print help config-file.ini
# 
# Which would then find comments defined like this in `config-file.ini`:
#
#   ;;; Main config Usage:help
#   ; Help comments in a config file
#   ; may start with a different comment character
#   ;;;/doc
#
#
#
# Example usage in a multi-function script:
#
#   #!usr/bin/env bash
#
#   ### Main help Usage:help
#   # The main help
#   ###/doc
#
#   ### Feature One Usage:feature_1
#   # Help text for the first feature
#   ###/doc
#
#   feature1() {
#       autohelp:check:section feature_1 "$@"
#       echo "Feature I"
#   }
#
#   ### Feature Two Usage:feature_2
#   # Help text for the second feature
#   ###/doc
#
#   feature2() {
#       autohelp:check:section feature_2 "$@"
#       echo "Feature II"
#   }
#
#   main() {
#       case "$1" in
#       feature1|feature2)
#           "$1" "$@"            # Pass the global script arguments through
#           ;;
#       *)
#           autohelp:check-no-null "$@"  # Check if main help was asked for, if so, or if no args, exit with help
#
#           # Main help not requested, return error
#           echo "Unknown feature"
#           exit 1
#           ;;
#       esac
#   }
#
#   main "$@"
#
###/doc

### autohelp:print [ SECTION [FILE] ] Usage:bbuild
# Print the specified section, in the specified file.
#
# If no file is specified, prints for current script file.
# If no section is specified, defaults to "help"
###/doc

HELPCHAR='#'

autohelp:print() {
    local input_line
    local section_string="${1:-}"; shift || :
    local target_file="${1:-}"; shift || :
    [[ -n "$section_string" ]] || section_string=help
    [[ -n "$target_file" ]] || target_file="$0"

    local sec_start='^\s*'"$HELPCHAR$HELPCHAR$HELPCHAR"'\s+(.+?)\s+Usage:'"$section_string"'\s*$'
    local sec_end='^\s*'"$HELPCHAR$HELPCHAR$HELPCHAR"'\s*/doc\s*$'
    local in_section=false

    while read input_line; do
        if [[ "$input_line" =~ $sec_start ]]; then
            in_section=true
            echo -e "\n${BASH_REMATCH[1]}\n======="

        elif [[ "$in_section" = true ]]; then
            if [[ "$input_line" =~ $sec_end ]]; then
                in_section=false
            else
                echo "$input_line" | sed -r "s/^\s*$HELPCHAR/ /;s/^  (\S)/\1/"
            fi
        fi
    done < "$target_file"

    if [[ "$in_section" = true ]]; then
            out:fail "Non-terminated help block."
    fi
}

### autohelp:paged Usage:bbuild
#
# Display the help in the pager defined in the PAGER environment variable
#
###/doc
autohelp:paged() {
    : ${PAGER=less}
    autohelp:print "$@" | $PAGER
}

### autohelp:check-or-null ARGS ... Usage:bbuild
# Print help if arguments are empty, or if arguments contain a '--help' token
#
###/doc
autohelp:check-or-null() {
    if [[ -z "$*" ]]; then
        autohelp:print help "$0"
        exit 0
    else
        autohelp:check:section "help" "$@"
    fi
}

### autohelp:check-or-null:section SECTION ARGS ... Usage:bbuild
# Print help section SECTION if arguments are empty, or if arguments contain a '--help' token
#
###/doc
autohelp:check-or-null:section() {
    . <(args:use:local section -- "$@") ; 
    if [[ -z "$*" ]]; then
        autohelp:print "$section" "$0"
        exit 0
    else
        autohelp:check:section "$section" "$@"
    fi
}

### autohelp:check ARGS ... Usage:bbuild
#
# Automatically print "help" sections and exit, if "--help" is detected in arguments
#
###/doc
autohelp:check() {
    autohelp:check:section "help" "$@"
}

### autohelp:check:section SECTION ARGS ... Usage:bbuild
# Automatically print documentation for named section and exit, if "--help" is detected in arguments
#
###/doc
autohelp:check:section() {
    local section arg
    section="${1:-}"; shift || out:fail "No help section specified"

    for arg in "$@"; do
        if [[ "$arg" =~ --help ]]; then
            cols="$(tput cols)"
            autohelp:print "$section" | fold -w "$cols" -s || autohelp:print "$section"
            exit 0
        fi
    done
}

##bash-libs: app/pyvenv.sh @ 6e4f511f (2.1.4)

##bash-libs: abspath.sh @ 6e4f511f (2.1.4)

### abspath:path RELATIVEPATH [ MAX ] Usage:bbuild
# Returns the absolute path of a file/directory
#
# MAX defines the maximum number of "../" relative items to process
#   default is 50
###/doc

function abspath:path {
    local workpath="$1" ; shift || :
    local max="${1:-50}" ; shift || :

    if [[ "${workpath:0:1}" != "/" ]]; then workpath="$PWD/$workpath"; fi

    workpath="$(abspath:collapse "$workpath")"
    abspath:resolve_dotdot "$workpath" "$max" | sed -r 's|(.)/$|\1|'
}

function abspath:collapse {
    echo "$1" | sed -r 's|/\./|/|g ; s|/\.$|| ; s|/+|/|g'
}

function abspath:resolve_dotdot {
    local workpath="$1"; shift || :
    local max="$1"; shift || :

    # Set a limit on how many iterations to perform
    # Only very obnoxious paths should fail
    local obnoxious_counter
    for obnoxious_counter in $(seq 1 $max); do
        # No more dot-dots - good to go
        if [[ ! "$workpath" =~ /\.\.(/|$) ]]; then
            echo "$workpath"
            return 0
        fi

        # Starts with an up-one at root - unresolvable
        if [[ "$workpath" =~ ^/\.\.(/|$) ]]; then
            return 1
        fi

        workpath="$(echo "$workpath"|sed -r 's@[^/]+/\.\.(/|$)@@')"
    done

    # A very obnoxious path was used.
    return 2
}

BBUILD_PYTHONVENV=""

### pyvenv:setup DIRNAME [PYTHONVERSION] Usage:bbuild
# Create a virtual environment directory
#
# DIRNAME - the name of the directory to be a virtual environment
# PYTHONVERSION - version of python to use, uses virtualenv's default if not specified
###/doc
pyvenv:setup() {
    . <(args:use:local venvdir ?pyversion -- "$@") ; 
    local useversion=(:)

    if [[ -n "$pyversion" ]]; then
        useversion+=(-p "$pyversion")
    fi

    virtualenv "${useversion[@]:1}" "$venvdir"
}

### pyvenv:ensure DIRNAME [PYTHONVERSION] Usage:bbuild
# Ensure a virtual environment directory is present; if not, create it.
#
# If a ./requirements.txt file exists, install requirements during creation.
#
# DIRNAME - the name of the directory to be a virtual environment
# PYTHONVERSION - version of python to use, uses virtualenv's default if not specified
###/doc
pyvenv:ensure() {
    . <(args:use:local venvdir ?pyversion -- "$@") ; 
    if [[ ! -f "$venvdir/bin/activate" ]]; then
        pyvenv:setup "$venvdir" "$pyversion"
        pyvenv:activate "$venvdir"
        reqfile="$(dirname "$venvdir")/requirements.txt"
        if [[ -f "$reqfile" ]]; then
            pip install -r "$reqfile"
        fi
        pyvenv:deactivate
    fi
}

### pyvenv:activate DIRNAME Usage:bbuild
# Activate a virtual environment directory
#
# DIRNAME - the name of the virtual environment directory.
###/doc
pyvenv:activate() {
    . <(args:use:local venvdir -- "$@") ; 
    if [[ -z "$BBUILD_PYTHONVENV" ]]; then
        PS1="${PS1:-}"
        . "$venvdir/bin/activate"
        BBUILD_PYTHONVENV="$(abspath:path "$venvdir")"
    else
        return 1
    fi
}

### pyvenv:deactivate Usage:bbuild
# Deactivate a virtual environment directory
###/doc
pyvenv:deactivate() {
    if [[ -n "$BBUILD_PYTHONVENV" ]]; then
        deactivate
        BBUILD_PYTHONVENV=false
    else
        return 1
    fi
}

### pyvenv:add LIBNAMES ... Usage:bbuild
# Add libraries to the virtual environment and save in a sidecar requirements.txt file
#
# returns: virtualenv code on failure, or
#
# 101 - virtualenv not activated through pyvenv:activate
###/doc
pyvenv:add() {
    if [[ -n "$BBUILD_PYTHONVENV" ]]; then
        pip install "$@" || return
        pip freeze > "$(dirname "$BBUILD_PYTHONVENV")/requirements.txt"
    else
        return 101
    fi
}
##bash-libs: app/hovercraft.sh @ 6e4f511f (2.1.4)

##bash-libs: varify.sh @ 6e4f511f (2.1.4)

### Varify Usage:bbuild
# Make a string into a valid variable name or file name
#
# Collapses any string of invalid characters into a single underscore
#
# For example
#
# 	varify:var "http://example.com"
#
# returns
#
# 	http_example.com
#
###/doc

### varify:var Usage:bbuild
#
# Valid characters for varify:var are:
#
# * a-z
# * A-Z
# * 0-9
# * underscore ("_")
###/doc
function varify:var {
    echo "$*" | sed -r 's/[^a-zA-Z0-9_]/_/g'
}

### varify:fil Usage:bbuild
#
# Valid characters for varify:fil are:
#
# * a-z
# * A-Z
# * 0-9
# * underscore ("_")
# * dash ("-")
# * period (".")
#
# Can be used to produce filenames.
#
###/doc
function varify:fil {
    echo "$*" | sed -r 's/[^a-zA-Z0-9_.-]/_/g'
}

##bash-libs: app/webbrowser.sh @ 6e4f511f (2.1.4)

### webbrowser Usage:bbuild
# Library to control web browsers
###/doc

##bash-libs: bincheck.sh @ 6e4f511f (2.1.4)

### bincheck:get COMMANDS ... Usage:bbuild
#
# Return the first existing binary
#
# Useful for finding an appropriate binary when you know
# different systems may supply binaries under different names.
#
# Returns the full path from `which` for the first executable
# encountered.
#
# Example:
#
# 	bincheck:get markdown_py markdown ./mymarkdown
#
# Tries in turn to get a `markdown_py`, then a `markdown`, and then a local `./mymarkdown`
#
###/doc

bincheck:get() {
    local BINEXE=
    for binname in "$@"; do
        # Some implementations of `which` print error messages
        # Not useful here.
        BINEXE=$(which "$binname" 2>/dev/null)

        if [[ -n "$BINEXE" ]]; then
            echo "$BINEXE"
            return 0
        fi
    done
    return 1
}

### bincheck:has NAMES ... Usage:bbuild
#
# Determine if at least one of the binaries listed is present and installed on the system
#
###/doc

bincheck:has() {
    [[ -n "$(bincheck:get "$@")" ]]
}

### bincheck:path NAME Usage:bbuild
#
# Determine the actual path to the command
#
# Relative paths are not expanded.
#
###/doc

bincheck:path() {
    local binname="$1"; shift || :

    [[ "$binname" =~ / ]] && { 
        # A relative path cannot be resolved, just check existence
        [[ -e "$binname" ]] && echo "$binname" || return 1

    } || binname="$(which "$binname" 2>/dev/null)"

    # `which` failed
    [[ -n "$binname" ]] || return 1

    [[ -h "$binname" ]] && {

        local pointedname="$(ls -l "$binname"|grep -oP "$binname.+"|sed "s|$binname -> ||")"
        bincheck:path "$pointedname" ; return "$?"
    
    } || echo "$binname"
}

### webbrowser:visit URL Usage:bbuild
# Visit a URL in a graphical web broswer.
#
# Will try to get the system's web browser, or try to locate any one of a wide selection of browsers.
###/doc
webbrowser:visit() {
    . <(args:use:local url -- "$@") ; 
    local runtime

    local browser_options=(
        sensible-browser # Ubuntu's shorthand for the system browser
        gnome-www-browser # Gnome's shorthand
        firefox opera chromium epiphany # popular browsers by bin name
        x-www-browser www-browser # System terminal-based browsers
        elinks
    )
    runtime="$(bincheck:get "${browser_options[@]}")" || return 1

    if [[ -z "$runtime" ]]; then
        "$runtime" "$url"
        return
    fi
    return 127
}

### hovercraft:build MAINFILE Usage:bbuild
# Build the presentation from the MAINFILE (.rst file), and print the path of the compiled presentation
###/doc

hovercraft:build() {
    . <(args:use:local mainfile -- "$@") ; 
    mkdir -p presentation-hovercraft
    local pdir="$(mktemp -d "presentation-hovercraft/$(varify:fil "$mainfile")-XXXX")"

    hovercraft "$mainfile" "$pdir"

    echo "$pdir/index.html"
}

### hovercraft:show MAINFILE [BROWSER] Usage:bbuild
# Build the presentation based on MAINFILE ;
#
# Opens a browser session with the presentation.
#
# If browser is not specified, attempts to use the default system browser.
###/doc

hovercraft:show() {
    . <(args:use:local mainfile ?browser -- "$@") ; 
    local presentation="file://$PWD/$(hovercraft:build "$mainfile")"

    if [[ -z "$browser" ]]; then
        webbrowser:visit "$presentation"
    else
        "$browser" "$presentation"
    fi
}

### hovercraft:serve MAINFILE [COMMAND ...] Usage:bbuild
# Build the presentation base on MAINFILE ;
#
# Use the specified command to serve the presentation through a web server.
#
# By default, the command is `python3 -m http.server 8090`
# run in the context of the built presentation's directory
###/doc

hovercraft:serve() {
    . <(args:use:local mainfile -- "$@") ; 
    local presentation_file="$(hovercraft:build "$mainfile")"
    local presentation_dir="$(dirname "$presentation_file")"

    cd "$presentation_dir"

    if [[ -z "$*" ]]; then
        python3 -m http.server 8090
    else
        "$@"
    fi
}

main() {
    . <(args:use:local ?action -- "$@") ; 
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
