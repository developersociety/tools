=======================
Blanc Development Tools
=======================

Tools for making development at Blanc quicker, easier and less error prone.

https://github.com/blancltd/tools

Installation
============

To install these tools::

    $ git clone git@github.com:blancltd/tools.git
    $ cd tools
    $ ./install

Usage
=====

blanc-branch-change
-------------------

Run this tool after you change branch. It:

* Installs all pip & NPM requirements are installed
* Grabs a copy of the live/demo database & media files
* Runs database migrations

It needs to be ran within a virtualenv and will error out if it detects it's not in a virtualenv.

Example of use:
~~~~~~~~~~~~~~~

::

    $ blanc-branch-change

Development
===========

Please contribute! If you find yourself needing to do the same thing over and over, or you keep
forgetting a process, or you just feel you're typing too much to do boring stuff... then create a
script to automate/help/optimise it. And then we can all benefit.
