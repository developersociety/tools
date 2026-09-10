#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# dev-update-aws-config replaces a file people depend on, so the parts worth checking are that it
# leaves an unchanged config alone, backs up before replacing, and doesn't hoard backups forever.
# Runs against a stubbed 1Password CLI.

BINDIR="$(cd "$(dirname "$0")/../bin" && pwd)"
# shellcheck source=tests/helpers.sh
source "$(dirname "$0")/helpers.sh"

make_workdir

write_stub op <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
    account) exit 0 ;;
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

printf '\n' | "$BINDIR/dev" update-aws-config alice >/dev/null
expect "the username is substituted into the template" \
    "[profile alice]" "$(head -n 1 "$CONFIG_FILE")"
expect "the first run leaves no backup behind" "0" "$(count_backups)"

printf '\n' | "$BINDIR/dev" update-aws-config alice >/dev/null
expect "re-running with no changes doesn't write a backup" "0" "$(count_backups)"

printf '\n' | "$BINDIR/dev" update-aws-config bob >/dev/null
expect "a changed config is written" "[profile bob]" "$(head -n 1 "$CONFIG_FILE")"
expect "replacing the config backs up the old one" "1" "$(count_backups)"

# Six older backups plus the one above is over the limit, so the oldest should be dropped.
for index in 1 2 3 4 5 6; do
    touch "$HOME/.aws/config.old.2020010${index}T000000Z"
done

printf '\n' | "$BINDIR/dev" update-aws-config carol >/dev/null
expect "old backups are pruned" "5" "$(count_backups)"

if [ -f "$HOME/.aws/config.old.20200101T000000Z" ]; then
    fail "the oldest backup should have been pruned first"
fi

# A failure reading the template must not leave the config missing or empty.
rm -f "$STUB_OP_TEMPLATE"
if printf '\n' | "$BINDIR/dev" update-aws-config dave >/dev/null 2>&1; then
    fail "a failed 'op read' should exit non-zero"
fi
expect "a failed run leaves the existing config in place" \
    "[profile carol]" "$(head -n 1 "$CONFIG_FILE")"

finish "config diffed, backed up and pruned, and survives a failed template read"
