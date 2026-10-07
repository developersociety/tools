#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# dev-update-aws-config replaces a file people depend on, so the parts worth checking are that the
# username reaches the template and that an existing config is moved aside rather than lost.
# Runs against a stubbed 1Password CLI.

BINDIR="$(cd "$(dirname "$0")/../bin" && pwd)"
# shellcheck source=tests/helpers.sh
source "$(dirname "$0")/helpers.sh"

make_workdir

write_stub op <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
    read) cat "$STUB_OP_TEMPLATE" ;;
    *) exit 1 ;;
esac
STUB

printf '[profile USERNAME]\nregion = eu-west-1\n' >"$WORKDIR/template"
export STUB_OP_TEMPLATE="$WORKDIR/template"

mkdir -p "$WORKDIR/home"
export HOME="$WORKDIR/home"
CONFIG_FILE="$HOME/.aws/config"

count_backups() {
    find "$HOME/.aws" -name "config.old.*" | wc -l | tr -d ' '
}

if "$BINDIR/dev" update-aws-config >/dev/null 2>&1; then
    fail "calling it without a username should exit non-zero"
fi

"$BINDIR/dev" update-aws-config alice >/dev/null
expect "the username is substituted into the template" \
    "[profile alice]" "$(head -n 1 "$CONFIG_FILE")"
expect "the first run leaves no backup behind" "0" "$(count_backups)"

"$BINDIR/dev" update-aws-config bob >/dev/null
expect "the new config is written" "[profile bob]" "$(head -n 1 "$CONFIG_FILE")"
expect "the previous config is moved aside, not overwritten" "1" "$(count_backups)"
expect "the backup holds the config it replaced" \
    "[profile alice]" "$(head -n 1 "$HOME"/.aws/config.old.*)"

finish "the username reaches the template, and the old config is kept"
