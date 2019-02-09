:title: Building Better Bash Scripts
:css: css/main.css

=====

Building Better Bash
====================

=====

* Who uses bash?
* Who thinks their bash scripts are elegant?

=====

A ``portplug.sh`` script to prevent insecure connections from casually leaking our activities.

::

    #!/bin/bash

    mode="$1"

    if [ "$mode" = on ]; then

    ufw deny 80
    ufw deny 8080
    ufw deny 25

    else

    ufw delete deny 80
    ufw delete deny 8080
    ufw delete deny 25

    fi

.. note::

    Many problems:

    * indentation
    * heavy repetition
    * no variable check
    * wrong test
    * safe mode not used

=====

Bash Unofficial Safe Mode
=========================

::
    set -euo pipefail

Steam bug was:

::

    rm -rf "$user_steam_dir/$app_dir"

.. note::

    User had a custom directory which was not detected by the update script.

    * did not delete system
    * deleted all user's owned files
    * including the attached backup

=====

::

    #!/usr/bin/env bash

    set -euo pipefail

    DEFAULT_PORTS=(80 8080 25)

    die() {
        echo "$*"
        exit 1
    }

    main() {
        # Safe dereference, shift generates the error
        local mode="${1:-}"; shift ||
            die "No mode (on/off) specified"


=====

::

      local port                                          
                                                          
      if [[ "$mode" = on ]]; then                         
          mode=(deny)                                     
      elif [[ "$mode" = off ]]; then                      
          mode=(delete deny)                              
      else                                                
          die "Invalid mode '$mode' specified"             
      fi                                                  
                                                          
      for port in "${DEFAULT_PORTS[@]}"; do               
          ufw "${mode[@]}" "$port"                        
      done                                                 
  }                                                        
                                                          
  main "$@"                                               


.. note::

    Fixed:

    * safe mode not used
    * indentation
    * heavy repetition
    * no variable check
    * wrong test

=====

Adding features
===============

* Make the ports list customizable on command line
* Differentiable error codes

=====

::

    #!/usr/bin/env bash

    set -euo pipefail

    DEFAULT_PORTS=(80 8080 25)

    readonly ERR_no_mode=10
    readonly ERR_no_error_code=101
    readonly ERR_NaN=102

    die() {
        local code="${1:-}"; shift ||
            die $ERR_no_error_code "No code supplied"
        [[ "$code" =~ ^[0-9]+$ ]] ||
            die $ERR_NaN "Bad code supplied [$code] "\
              "while processing message '$*'"

        echo "$*" >&2
        exit "$code"
    }

=====

::

    function setmode() {
        declare -n mode
        mode="$1"; shift

        declare -n ports
        ports="$1"; shift

        for port in "$@"; do
            ufw "${mode[@]}" "${port[@]}"
        done
    }

    function main() {
        local mode="${1:-}"; shift ||
            die $ERR_no_mode "Please specify a mode ('on' or 'off')"
        local ports=("${DEFAULT_PORTS[@]}")

=====

::

        if [[ "$mode" = on ]]; then
            mode=(deny)
        elif [[ "$mode" = off ]]; then
            mode=(delete deny)
        else
            die $ERR_no_mode "Invalid mode passed '$mode'"
        fi

        if [[ -n "$*" ]]; then ports=("$@") ; fi

        echo "Processing ${ports[*]}"
        setmode mode ports
        echo "Could not process ${ports[*]}"
    }

    main "$@"

.. note::

    * Functions = paragraphs // always do it
    * 
