#&include std/autohelp.sh
#&include std/out.sh
##bash-libs: syntax-extensions.sh @ 6421286a (2.0.1)

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
        failmsg="\"Internal : could not get '$argname' in function arguments\""
        posfailmsg="Internal: positional argument '$argname' encountered after optional argument(s)"

        if [[ "$argname" =~ ^\? ]]; then
            echo "$SYNTAXLIB_scope ${argname:1}=$argone; shift || :"
            pos_ok=false

        elif [[ "$argname" =~ ^\* ]]; then
            [[ "$pos_ok" != false ]] || out:fail "$posfailmsg"
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

##bash-libs: tty.sh @ 6421286a (2.0.1)

tty:is_ssh() {
    [[ -n "$SSH_TTY" ]] || [[ -n "$SSH_CLIENT" ]] || [[ "$SSH_CONNECTION" ]]
}

tty:is_pipe() {
    [[ ! -t 1 ]]
}

##bash-libs: colours.sh @ 6421286a (2.0.1)

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

##bash-libs: out.sh @ 6421286a (2.0.1)

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
##bash-libs: bincheck.sh @ 6421286a (2.0.1)

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
##bash-libs: varify.sh @ 6421286a (2.0.1)

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

##bash-libs: abspath.sh @ 6421286a (2.0.1)

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

### pyvenv:setup DIRNAME [PYTHONVERSION] Usage:bashdoc
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

### pyvenv:ensure DIRNAME [PYTHONVERSION] Usage:bashdoc
# Ensure a virtual environment directory is present; if not, create it.
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

### pyvenv:activate DIRNAME Usage:bashdoc
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

### pyvenv:deactivate Usage:bashdoc
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

### pyvenv:add LIBNAMES ... Usage:bashdoc
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

### hovercraft:serve MAINFILE Usage:bashdoc
# Build the presentation based on MAINFILE
#
# Opens a browser session with the presentation
###/doc

hovercraft:serve() {
    . <(args:use:local mainfile -- "$@") ; 
    mkdir -p presentation-hovercraft
    local pdir="$(mktemp -d "presentation-hovercraft/$(varify:fil "$mainfile")-XXXX")"

    hovercraft "$mainfile" "$pdir"
    local runtime
    runtime="$(bincheck:get sensible-browser firefox chromium chrome gnome-www-browser epiphany x-www-browser www-browser)" || return 1

    "$runtime" "$pdir/index.html"
}

main() {
    . <(args:use:local ?action -- "$@") ; 
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
