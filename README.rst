=========================================
The Developer Society - Development Tools
=========================================

Tools for making development at The Developer Society quicker, easier and less error prone.

https://github.com/developersociety/tools

Installation
============

To install these tools:

.. code:: console

    $ git clone git@github.com:developersociety/tools.git
    $ cd tools/bin
    $ pwd

Add the bin directory to your ``$PATH``, by editing your ``~/.bash_profile``:

.. code:: bash

    export PATH="/path/to/tools/bin:$PATH"


Usage
=====

dev-reset
---------

Run this tool whenever you need to reset the current environment. For example when you change
branch or want to reset things to a virgin state.

It will:

* Removes all packages currently installed in the current virtualenv
* Installs all pip & NPM requirements are installed
* Grabs a copy of the live/demo database & media files
* Runs database migrations

It needs to be ran within a virtualenv and will error out if it detects it's not in a virtualenv.

Example of use:
~~~~~~~~~~~~~~~

.. code:: console

    $ dev-reset


dev-clone
---------

This tool will `git-clone` a repo from Dev's github and setup virtualenvwrapper for you, with a
virtualenv and a virtualenvwrapper project for you.

It requires virtualenvwrapper to be installed with the `$PROJECT_HOME` environment variable set
correctly.

It will:

* `git-clone` the repo from Dev's github
* setup virtualenv with virtualenvwrapper
* setup virtualenvwrapper project dir

Example of use:
~~~~~~~~~~~~~~~

::

    $ dev-clone cofebristol


dev-createsuperuser
-------------------

Tries to add a Django superuser to the current project. The superuser will be created with the
following credentials:

**Username:** `_dev`
**Password:** `password`

Example of use:
~~~~~~~~~~~~~~~

::

    $ dev-createsuperuser


dev-wipeenv
-----------

Removes all packages in the current virtualenv.

Example of use:
~~~~~~~~~~~~~~~

.. code-block:: console

    $ dev-wipeenv


Development
===========

Please contribute! If you find yourself needing to do the same thing over and over, or you keep
forgetting a process, or you just feel you're typing too much to do boring stuff... then create a
script to automate/help/optimise it. And then we can all benefit.
