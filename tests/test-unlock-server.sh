#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# dev-unlock-server hands a passphrase to a server's initramfs and then waits for it to boot.
# Runs against stubbed op, ssh and sleep, so nothing is contacted and nothing actually waits.

BINDIR="$(cd "$(dirname "$0")/../bin" && pwd)"
# shellcheck source=tests/helpers.sh
source "$(dirname "$0")/helpers.sh"

make_workdir

write_stub op <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
    account) [ -z "${STUB_OP_SIGNED_OUT:-}" ] ;;
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

if [ "$command" = "cryptroot-unlock" ]; then
    read -r passphrase || true
    echo "unlock $target $passphrase" >> "$STUB_SSH_LOG"
    exit 0
fi

echo "boot-check $target" >> "$STUB_SSH_LOG"
case " ${STUB_UP_HOSTS:-} " in
    *" $target "*) exit 0 ;;
esac
exit 1
STUB

write_stub sleep <<'STUB'
#!/usr/bin/env bash
exit 0
STUB

export STUB_OP_LOG="$WORKDIR/op.log"
export STUB_SSH_LOG="$WORKDIR/ssh.log"

if STUB_OP_SIGNED_OUT=1 "$BINDIR/dev" unlock-server one.example >/dev/null 2>&1; then
    fail "being signed out of 1Password should exit non-zero"
fi

: >"$STUB_OP_LOG"
: >"$STUB_SSH_LOG"
STUB_UP_HOSTS="one.example two.example" \
    "$BINDIR/dev" unlock-server one.example two.example >/dev/null

expect "each host's passphrase is read from its own 1Password item" \
    $'op://aizi3l3vxjc52mboshwj7bbytq/one.example/password\nop://aizi3l3vxjc52mboshwj7bbytq/two.example/password' \
    "$(cat "$STUB_OP_LOG")"

expect "each host is unlocked as root and then checked for boot, in order" \
    $'unlock root@one.example passphrase-for-op://aizi3l3vxjc52mboshwj7bbytq/one.example/password\nboot-check one.example\nunlock root@two.example passphrase-for-op://aizi3l3vxjc52mboshwj7bbytq/two.example/password\nboot-check two.example' \
    "$(cat "$STUB_SSH_LOG")"

OUTPUT=$(DEV_UNLOCK_TIMEOUT=1 STUB_UP_HOSTS="" \
    "$BINDIR/dev" unlock-server slow.example 2>&1 >/dev/null)

expect_contains "a host which never boots should warn on stderr" \
    "$OUTPUT" "did not come back"

finish "passphrases fetched per host, unlocked in order, and slow servers warn"
