# shellcheck shell=bash
#
# Shared scaffolding for the tests. Assertions report and carry on rather than aborting, so one
# run tells you everything that's broken instead of only the first thing.

FAILED=0

# Creates a temporary working directory which cleans itself up, with a stub directory already at
# the front of $PATH for fake versions of git, ssh, op and friends.
make_workdir() {
    WORKDIR=$(mktemp -d)
    trap 'rm -rf "$WORKDIR"' EXIT

    mkdir -p "$WORKDIR/stub"
    export PATH="$WORKDIR/stub:$PATH"
}

# Writes an executable stub into the stub directory, reading its body from stdin.
write_stub() {
    cat >"$WORKDIR/stub/$1"
    chmod +x "$WORKDIR/stub/$1"
}

expect() {
    local description="$1" expected="$2" actual="$3"

    if [ "$expected" != "$actual" ]; then
        fail "$description"
        echo "  expected: $expected"
        echo "  actual:   $actual"
    fi
}

fail() {
    echo "FAIL: $1"
    FAILED=1
}

finish() {
    if [ "$FAILED" != 0 ]; then
        exit 1
    fi

    echo "PASS: $1"
}
