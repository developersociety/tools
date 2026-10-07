#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# dev-clone works out the repo URL and which Python to build the virtualenv with. Both are easy
# to break silently, so they run here against stubbed git, pyenv and virtualenvwrapper - no
# network, no real virtualenvs.

BINDIR="$(cd "$(dirname "$0")/../bin" && pwd)"
REAL_GIT=$(command -v git)
# shellcheck source=tests/helpers.sh
source "$(dirname "$0")/helpers.sh"

make_workdir

mkdir -p "$WORKDIR/fixtures/plain" "$WORKDIR/fixtures/toxini" \
    "$WORKDIR/projects" "$WORKDIR/virtualenvs"

touch "$WORKDIR/fixtures/plain/README.md"
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

run_clone plain someproject
expect "a bare name is assumed to be a developersociety repo" \
    "git@github.com:developersociety/someproject.git" "$(cat "$STUB_CLONE_URI")"
expect "a repo without a tox.ini gets a plain virtualenv" \
    "--force someproject" "$(cat "$STUB_MKPROJECT_ARGS")"

run_clone plain someorg/otherproject
expect "an org/repo argument is used as given" \
    "git@github.com:someorg/otherproject.git" "$(cat "$STUB_CLONE_URI")"

run_clone toxini toxproject
expect "tox.ini's basepython picks the interpreter" \
    "--force --python=python3.11 toxproject" "$(cat "$STUB_MKPROJECT_ARGS")"

if "$BINDIR/dev" clone someproject >/dev/null 2>&1; then
    fail "cloning into an existing directory should exit non-zero"
fi

finish "repo names and the tox.ini Python version both behave"
