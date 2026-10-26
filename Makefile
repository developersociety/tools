SHELL=/bin/bash
.DEFAULT_GOAL := help

SHELL_SOURCES = bin/dev*


# -------------------------------
# Common targets for Dev projects
# -------------------------------
#
# Edit these targets so they work as expected on the current project.
#
# Remember there may be other tools which use these targets, so if a target is not suitable for
# the current project, then keep the target and simply make it do nothing.

help: ## This help dialog.
help:
	@awk '/^[\-[:alnum:]]*: ##/ { split($$0, x, "##"); printf "%20s%s\n", x[1], x[2]; }' $(MAKEFILE_LIST)

install-local: ## Install the tools needed to work on this project.
install-local:
	brew install shellcheck shfmt

format: ## Run this project's code formatters.
format:
	shfmt --write $(SHELL_SOURCES)

lint: ## Lint the project.
lint:
	shellcheck $(SHELL_SOURCES)
	shfmt --diff $(SHELL_SOURCES)
