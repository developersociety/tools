#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# dev-clone works out the repo URL, whether the project needs a virtualenv, and which Python to
# build it with. All of that is easy to break silently, so it runs here against stubbed git,
# pyenv and virtualenvwrapper - no network, no real virtualenvs.

BINDIR="$(cd "$(dirname "$0")/../bin" && pwd)"
REAL_GIT=$(command -v git)
# shellcheck source=tests/helpers.sh
source "$(dirname "$0")/helpers.sh"

make_workdir

mkdir -p "$WORKDIR/fixtures/empty" "$WORKDIR/fixtures/python" "$WORKDIR/fixtures/toxini" \
    "$WORKDIR/projects" "$WORKDIR/virtualenvs"

touch "$WORKDIR/fixtures/empty/README.md"
touch "$WORKDIR/fixtures/python/pyproject.toml"
printf '[testenv]\nbasepython = python3.11\n' >"$WORKDIR/fixtures/toxini/tox.ini"

write_stub git <<STUB
#!/usr/bin/env bash
set -euo pipefail
if [ "\${1:-}" = "clone" ]; then
    echo "\$2" > "\$STUB_CLONE_URI"
    mkdir -p "\$3"
    cp -R "\$STUB_FIXTURE"/. "\$3"/
    "$REAL_GIT" init --quiet "\$3"
    exit 0
fi
STUB

write_stub pyenv <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
    latest) echo "$2.99" ;;
    which) echo "/fake/bin/$2" ;;
    *) exit 1 ;;
esac
STUB

cat >"$WORKDIR/virtualenvwrapper.sh" <<'STUB'
mkproject() {
    # "$@" rather than "$*", as dev-clone sets IFS to newline and tab.
    echo "$@" > "$STUB_MKPROJECT_ARGS"
}
STUB

export PROJECT_HOME="$WORKDIR/projects"
export WORKON_HOME="$WORKDIR/virtualenvs"
export VIRTUALENVWRAPPER_SCRIPT="$WORKDIR/virtualenvwrapper.sh"
export STUB_CLONE_URI="$WORKDIR/clone-uri"
export STUB_MKPROJECT_ARGS="$WORKDIR/mkproject-args"

run_clone() {
    # The confirmation prompt reads a line, so give it one.
    export STUB_FIXTURE="$WORKDIR/fixtures/$1"
    shift
    rm -f "$STUB_CLONE_URI" "$STUB_MKPROJECT_ARGS"
    printf '\n' | "$BINDIR/dev" clone "$@" >/dev/null
}

mkproject_args() {
    if [ -f "$STUB_MKPROJECT_ARGS" ]; then
        cat "$STUB_MKPROJECT_ARGS"
    else
        echo "no mkproject"
    fi
}

run_clone empty someproject
expect "a bare name is assumed to be a developersociety repo" \
    "git@github.com:developersociety/someproject.git" "$(cat "$STUB_CLONE_URI")"
expect "a project with no Python files gets no virtualenv" "no mkproject" "$(mkproject_args)"

run_clone empty someorg/otherproject
expect "an org/repo argument is used as given" \
    "git@github.com:someorg/otherproject.git" "$(cat "$STUB_CLONE_URI")"

run_clone empty https://github.com/someorg/urlproject
expect "a browser URL is turned into an SSH remote" \
    "git@github.com:someorg/urlproject.git" "$(cat "$STUB_CLONE_URI")"

run_clone python pythonproject
expect "a project with a pyproject.toml gets a virtualenv" \
    "--force pythonproject" "$(mkproject_args)"

run_clone toxini toxproject
expect "tox.ini's basepython picks the interpreter" \
    "--force --python=/fake/bin/python toxproject" "$(mkproject_args)"

# The workspace points at the virtualenv's interpreter, so it has to exist by the time it's read.
mkdir -p "$WORKON_HOME/codeproject/bin"
printf '#!/bin/sh\n' >"$WORKON_HOME/codeproject/bin/python"
chmod +x "$WORKON_HOME/codeproject/bin/python"

run_clone python --vscode codeproject
WORKSPACE_FILE="$PROJECT_HOME/codeproject/codeproject.code-workspace"

if [ ! -f "$WORKSPACE_FILE" ]; then
    fail "--vscode didn't write a workspace file"
else
    expect "the workspace points at the project's interpreter" \
        "1" "$(grep -c "$WORKON_HOME/codeproject/bin/python" "$WORKSPACE_FILE")"
    expect "the workspace file is hidden from git" \
        "1" "$(grep -c "codeproject.code-workspace" "$PROJECT_HOME/codeproject/.git/info/exclude")"
fi

run_clone python plainproject
if [ -f "$PROJECT_HOME/plainproject/plainproject.code-workspace" ]; then
    fail "a workspace file was written without --vscode"
fi

if "$BINDIR/dev" clone someproject >/dev/null 2>&1; then
    fail "cloning into an existing directory should exit non-zero"
fi

finish "repo names, Python detection and the VS Code workspace all behave"
