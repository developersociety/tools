=========================================
The Developer Society - Development Tools
=========================================

Tools for making development at The Developer Society quicker, easier and less error prone.

https://github.com/developersociety/tools

Installation
============

To install these tools::

    $ git clone git@github.com:developersociety/tools.git
    $ cd tools
    $ ./install

Add this to your `.bashrc`::

    source ~/tools/source/dev-clone
    source ~/tools/source/django-bash-completion


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

::

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


dev-add-git-hooks
-----------------

Adds the Git Hooks to the current project. The [Git Hooks section](#user-content-git-hooks)
gives more information about the individual Git Hooks.

Example of use:
~~~~~~~~~~~~~~~

::

    $ dev-add-git-hooks


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

Removes all packages in the current virtualenv. It's likely you don't want to do this very often
and you're actually looking for [dev-reset](#user-content-dev-reset), which runs
`dev-wipeenv` as part of its run.

Example of use:
~~~~~~~~~~~~~~~

::

    $ dev-wipeenv


Git Hooks
=========

The following Git Hooks are supplied with the Tools. They can be added to any repository by using
the [dev-add-git-hooks](#user-content-dev-add-git-hooks) command.

pre-commit
----------

If the current project is configured to use Tox, then it will attempt to run the Flake8 and Isort
Tox environments.

pre-push
--------

If the current project is configured to use Tox, then it will do a full Tox run.


Django Manage Bash Autocomplete
===============================

Add the following line to your `.bashrc` to enable autocomplete for Django's `./manage.py` script::

    source ~/tools/source/django-bash-completion

Now pressing `<tab>` will autocomplete `./manage.py` commands.


Development
===========

Please contribute! If you find yourself needing to do the same thing over and over, or you keep
forgetting a process, or you just feel you're typing too much to do boring stuff... then create a
script to automate/help/optimise it. And then we can all benefit.
