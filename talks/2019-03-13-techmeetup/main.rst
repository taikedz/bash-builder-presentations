:title: Building Better Bash Scripts
:css: css/main.css

Pre-presentation prep:

* open our-pxe and remaster.sh in a new CLI
* open scripts/ in a new CLI and `vim *-portplug.sh`
* open bash-libs in new CLI
* open github/taikedz/ in new CLI
    * ensure access to
        * test.sh from bash-libs
        * alpacka -- paf
        * git-shortcuts
        * webserver.sh
* open https://github.com/taikedz/bash-builder/tree/master/docs in a browser

=====

Building Better Bash
====================

Tai Kedzierski

2019's March 13th TechMeetup

.. note::

    I've heard justification for 03/13/19 as "it's easier to say"

=====

* Who uses bash?
* Who thinks their bash scripts are elegant?

.. note::

    Show of hands.
    
    * How many sysadmins?
    * How many "devops"?
    * How many non-ops people use it?

=====

(Full disclaimer|For shame): I used to be awful too

.. note::

    * our-pxe -  a very dirty script for creating a PXE ISO from Ubuntu
    * remaster.sh - a slightly less dirty script

=====

Why use bash?
=============

1. You already know it* a little
2. You need to use programs' outputs
    * file management, firewall interaction, automation of CLI tool, automation of obscure tool ...
3. Any program is a library
4. More advanced syntax than plain old :code:`/bin/sh`

* if you're in some sort of ops or Linux sysadmin role

.. note::

    1. ... if you use Linux command lines
    2. Some programs simply don't have libraries and bindings in your languages
    3. jq , mysql , ssh , iptables, mount ...
    4. but language feature comparison is for another time

=====

Let's follow a script's development
===================================

=====

A :code:`portplug.sh` script to block ports.

Useful for seeing if anything breaks if we switch off known insecure connections...

.. note::

    01

    Many problems:

    * indentation
    * heavy repetition
    * no variable check
    * specific bash
    * uses single `[`
    * uses numeric argument
    * safe mode not used

=====

Bash Unofficial Safe Mode
=========================


.. code:: sh

    set -euo pipefail

.. note::

    02

    * -e - exit on error
    * -u - uninitialized var is error
    * -o pipefail - error in any part of pipe is error

=====

Steam Bug
=========

"Steam Bug" was:

.. code:: sh

    rm -rf "$user_steam_dir/$app_dir"

.. note::

    User had a custom directory which was not detected by the update script.

    App directory was not populated correctly

    * did not delete system
    * deleted all user's owned files
    * including the attached backup

======

Fix the script a little

.. note::

    02

    * runs any bash
    * safe mode - used
    * variable checked to be explicit value
    * heavy repetition avoided
    * indentation added
    * uses bash conditional blocks
    * no naked code

=====

Adding features
===============

* Make the ports list customizable on command line
* Differentiable error codes
* Pass an array by reference
* Add a help function

.. note::

    03

    * Functions = paragraphs // always do it
    * Use `function` keyword explicitly so it uses bash
    * `declare -n` allows using a value as a pointer to caller function's variable

=====

Good Practices
==============

* Separate your functions into logically grouped files
* Namespace the functions of each script

.. code:: sh

    # `:` , `@` , `.` , and even `#` are perfectly
    #   valid function name characters

    out:warn() { echo -e "\n\tWARN: $*\n" >&2 ; }

.. note::

    We can do even better than this

    Some stuff we re-use on scripts - script after script - should go in their own file

    And they should also have a namespace

=====

Good Practices
==============

* Don't use global variables
    * if you MUST, then namespace them too
* Name your function variables
* Report errors properly

.. code:: sh

    NAMESPACE_varname="value"

=====

.. code:: sh

    function files:copy() {
        local from_d dest_d
        from_d="${1:-}"; shift || { echo "No source dir specified"; exit 10; }
        dest_d="${1:-}"; shift || { echo "No destination dir specified"; exit 10; }

        #... and the actual activities
    }

.. note::

    I used to write a lot of code like this

    The more arguments the more boilerplate

    Variable setup sometimes took up 1/2 the function code!

=====

.. code:: sh

    $%function copyfiles(from_d dest_d) {

        #... straight to the actual activities
    }

.. note::

    I now write code like this

    Using a macro pattern replacer built in to a tool

=====

Bash Builder
============

* re-use common snippets
* add help processing
* add syntax sugars
* namespace functions

.. note::
    
    04

    * Multiple files
        * no double-inclusion
    * includes from the perspecitve of the main built script
    * namespace functions

=====

Other scripts
=============

* test.sh
* alpacka
* git shortcuts
* hovercraft

=====

webserver.sh
============

A travesty!

.. note::

    AGPL licensed because you shoud have to admit to being awful

=====

Other items
===========

* autohelp
* bashdoc
* tarSH

====

License.txt
===========

* LGPLv3

.. note::

    * Bash scripts are distributed as source anyway
    * Encourage bash scripters to re-use code
    * No stipulations on surrounding project
        * Most importantly: make bash sciprting better

=====

Hands up!
=========

Is this useful?

.. note::

    * Sysadmins who might find this useful?
    * Will exhort their sysadmins too code this way?
    * Why think their Sysadmins masquerade as devops?
