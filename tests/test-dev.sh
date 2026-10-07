#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# The dev dispatcher finds its subcommands by looking for sibling dev-* scripts, and builds all
# of its help from the comment block in each one. Both are checked here: dispatch and discovery
# against a throwaway copy of bin with an extra command dropped in, and the documentation against
# the real commands.

SOURCE_BINDIR="$(cd "$(dirname "$0")/../bin" && pwd)"
# shellcheck source=tests/helpers.sh
source "$(dirname "$0")/helpers.sh"

make_workdir

cp -R "$SOURCE_BINDIR" "$WORKDIR/bin"
BINDIR="$WORKDIR/bin"

cat >"$BINDIR/dev-madeupcommand" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# help: A command invented by the tests
#
# Usage:
#   dev madeupcommand [args]

echo "got: $@"
STUB
chmod +x "$BINDIR/dev-madeupcommand"

expect "arguments are passed through untouched" \
    "got: --flag one two" "$("$BINDIR/dev" madeupcommand --flag one two)"

expect_contains "a newly added command should appear in 'dev help' without being registered" \
    "$("$BINDIR/dev" help)" "madeupcommand"

expect "commands are also runnable directly, without the dispatcher" \
    "got: direct" "$("$BINDIR/dev-madeupcommand" direct)"

for INVOCATION in "" "-h" "--help" "help"; do
    expect_contains "'dev ${INVOCATION}' should print the usage summary" \
        "$("$BINDIR/dev" ${INVOCATION:+"$INVOCATION"})" "Usage: dev <command>"
done

if "$BINDIR/dev" no-such-command >/dev/null 2>&1; then
    fail "an unknown command should exit non-zero"
fi

expect_contains "an unknown command should say which one it didn't recognise" \
    "$("$BINDIR/dev" no-such-command 2>&1 || true)" "Unknown command: no-such-command"

if "$BINDIR/dev" help no-such-command >/dev/null 2>&1; then
    fail "'dev help' for an unknown command should exit non-zero"
fi

# A file which isn't executable isn't a command.
touch "$BINDIR/dev-notexecutable"
if "$BINDIR/dev" notexecutable >/dev/null 2>&1; then
    fail "a non-executable dev-* file shouldn't be runnable as a command"
fi

# Every real command has to document itself, since "dev help" and each script's --help are both
# generated from the comment block in the script. A tool added without one fails here.
for SCRIPT_PATH in "$SOURCE_BINDIR"/dev-*; do
    NAME="${SCRIPT_PATH##*/dev-}"

    HELP_OUTPUT=$("$SOURCE_BINDIR/dev" help "$NAME")
    expect_contains "'dev help $NAME' doesn't document a 'dev $NAME' usage line" \
        "$HELP_OUTPUT" "dev $NAME"

    expect "'$NAME --help' matches 'dev help $NAME'" "$HELP_OUTPUT" "$("$SCRIPT_PATH" --help)"

    expect_contains "'$NAME' is missing from the 'dev help' summary list" \
        "$("$SOURCE_BINDIR/dev" help)" "  $NAME "
done

finish "subcommands are discovered, dispatched, and all document themselves"
