#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# dev-wipeenv uninstalls everything in sight, so the parts worth pinning down are that it refuses
# to run outside a virtualenv and that it never uninstalls pip itself. Runs against a stubbed pip.

BINDIR="$(cd "$(dirname "$0")/../bin" && pwd)"
# shellcheck source=tests/helpers.sh
source "$(dirname "$0")/helpers.sh"

make_workdir

write_stub pip <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
    list) cat "$STUB_PIP_PACKAGES" ;;
    uninstall) shift 2; echo "$*" > "$STUB_PIP_UNINSTALLED" ;;
esac
STUB

export STUB_PIP_PACKAGES="$WORKDIR/packages"
export STUB_PIP_UNINSTALLED="$WORKDIR/uninstalled"

# Without a virtualenv the script has to say so, not fall over on an unset variable.
expect "running outside a virtualenv explains itself" "Must be in a virtual env" \
    "$(
        unset VIRTUAL_ENV
        "$BINDIR/dev" wipeenv 2>&1 || true
    )"

if (
    unset VIRTUAL_ENV
    "$BINDIR/dev" wipeenv >/dev/null 2>&1
); then
    fail "running outside a virtualenv should exit non-zero"
fi

export VIRTUAL_ENV="$WORKDIR/fake-venv"

cat >"$STUB_PIP_PACKAGES" <<'PACKAGES'
pip==25.0
setuptools==80.0
wheel==0.45
django==5.2
requests==2.32
PACKAGES

rm -f "$STUB_PIP_UNINSTALLED"
"$BINDIR/dev" wipeenv >/dev/null
expect "pip, setuptools and wheel are left alone" \
    "django==5.2 requests==2.32" "$(cat "$STUB_PIP_UNINSTALLED")"

cat >"$STUB_PIP_PACKAGES" <<'PACKAGES'
pip==25.0
setuptools==80.0
PACKAGES

expect "an already-empty virtualenv says there's nothing to do" "Nothing to remove" \
    "$("$BINDIR/dev" wipeenv 2>/dev/null)"

finish "refuses to run outside a virtualenv, and never uninstalls pip"
