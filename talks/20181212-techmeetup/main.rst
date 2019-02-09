:title: Building Better Bash Scripts
:css: css/main.css

=====

Building Better Bash
====================

.. note::

    * open bash-libs in new cli
    * open github/taikedz in new cli
    * ensure we are in scrpts/ dir for demo

=====

* Who uses bash?
* Who thinks their bash scripts are elegant?

=====

Why use bash?
=============

1. You already know it (if you use command lines)
2. You need to use programs' outputs (which don't have ibraries)
    * file management, firewall interaction, automation of CLI tool, automation of obscure tool ...
3. Any program is a library

=====

A ``portplug.sh`` script to prevent insecure connections from casually leaking our activities.

.. note::

    01

    Many problems:

    * indentation
    * heavy repetition
    * no variable check
    * specific bash
    * safe mode not used

=====

Bash Unofficial Safe Mode
=========================


::
    set -euo pipefail

.. note::

    02

    * -e - exit on error
    * -u - uninitialized var is error
    * -o pipefail - error in any part of pipe is error
    
    no naed code

=====

Steam Bug
=========

Steam bug was:

::

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

=====

Adding features
===============

* Make the ports list customizable on command line
* Differentiable error codes
* Pass an array by reference
* Add a help function

.. note::

    04

    * Functions = paragraphs // always do it
    * Use `function` keyword explicitly so it uses bash
    * `declare -n` allows using a value as a pointer to caller function's variable

=====

Bash Builder
============

* re-use common snippets
* add help processing
* add syntax sugars
* namespace functions

.. note::
    
    05

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
