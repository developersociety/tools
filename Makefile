SHELL=/bin/bash
.DEFAULT_GOAL := help


# -------------------------------
# Common targets for Dev projects
# -------------------------------
#
# Edit these targets so they work as expected on the current project.
#
# Remember there may be other tools which use these targets, so if a target is not suitable for
# the current project, then keep the target and simply make it do nothing.

help: ## This help dialog.
help: help-display

install-local: ## Install the tools needed to work on this project.
install-local: brew-install-local

check: ## Check for any obvious errors in the project's setup.
check: lint test

format: ## Run this project's code formatters.
format: shell-format

lint: ## Lint the project.
lint: shell-lint shell-format-check

test: ## Run this project's tests.
test: shell-test


# ---------------
# Utility targets
# ---------------
#
# Targets which are used by the common targets. You likely want to customise these per project,
# to ensure they're pointing at the correct directories, etc.

# Installs
brew-install-local:
	brew install shellcheck shfmt


# Shell
SHELL_SOURCES = bin/dev* tests/*.sh

shell-lint:
	shellcheck $(SHELL_SOURCES)

shell-format:
	shfmt --indent 4 --write $(SHELL_SOURCES)

shell-format-check:
	shfmt --indent 4 --diff $(SHELL_SOURCES)

shell-test:
	@for test in tests/test-*.sh; do \
	    echo "== $$test"; \
	    "$$test" || exit 1; \
	done


# Help
help-display:
	@awk '/^[\-[:alnum:]]*: ##/ { split($$0, x, "##"); printf "%20s%s\n", x[1], x[2]; }' $(MAKEFILE_LIST)
