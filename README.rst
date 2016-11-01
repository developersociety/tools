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

Add this to your `.bashrc`::

    source ~/tools/source/blanc-clone

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

blanc-clone
-------------------

This tool will `git-clone` a repo from Blanc's github and setup virtualenvwrapper for you, with a
virtualenv and a virtualenvwrapper project for you.

It requires virtualenvwrapper to be installed with the `$PROJECT_HOME` environment variable set
correctly.

It will:

* `git-clone` the repo from Blanc's github
* setup virtualenv with virtualenvwrapper
* setup virtualenvwrapper project dir

Example of use:
~~~~~~~~~~~~~~~

::

    $ blanc-clone cofebristol


Development
===========

Please contribute! If you find yourself needing to do the same thing over and over, or you keep
forgetting a process, or you just feel you're typing too much to do boring stuff... then create a
script to automate/help/optimise it. And then we can all benefit.
