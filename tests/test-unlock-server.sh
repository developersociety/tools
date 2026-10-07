#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# dev-unlock-server reads a passphrase from 1Password and hands it to a server's initramfs. Runs
# against stubbed op and ssh, so nothing is contacted and no real passphrase is involved.

BINDIR="$(cd "$(dirname "$0")/../bin" && pwd)"
# shellcheck source=tests/helpers.sh
source "$(dirname "$0")/helpers.sh"

make_workdir

write_stub op <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
    read)
        echo "$2" >> "$STUB_OP_LOG"
        echo "passphrase-for-$2"
        ;;
esac
STUB

write_stub ssh <<'STUB'
#!/usr/bin/env bash
set -euo pipefail

command="${*: -1}"
target="${*: -2:1}"

read -r passphrase || true
echo "$command $target $passphrase" >> "$STUB_SSH_LOG"
STUB

export STUB_OP_LOG="$WORKDIR/op.log"
export STUB_SSH_LOG="$WORKDIR/ssh.log"

if "$BINDIR/dev" unlock-server >/dev/null 2>&1; then
    fail "calling it without a hostname should exit non-zero"
fi

: >"$STUB_OP_LOG"
: >"$STUB_SSH_LOG"
"$BINDIR/dev" unlock-server one.example >/dev/null

expect "the passphrase is read from the host's own 1Password item" \
    "op://aizi3l3vxjc52mboshwj7bbytq/one.example/password" "$(cat "$STUB_OP_LOG")"

expect "the passphrase is piped to cryptroot-unlock as root" \
    "cryptroot-unlock root@one.example passphrase-for-op://aizi3l3vxjc52mboshwj7bbytq/one.example/password" \
    "$(cat "$STUB_SSH_LOG")"

finish "the passphrase is fetched for the right host and piped to cryptroot-unlock"
