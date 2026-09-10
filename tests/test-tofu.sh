#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# "dev tofu env" picks env vars out of the tofu state by name and has to leave alone the
# random_password resources tofu uses internally, and setting one has to remove it from the state
# before re-importing it. "dev tofu all" has to visit every project directory. Runs against a
# stubbed aws-vault, so no AWS credentials are involved.

BINDIR="$(cd "$(dirname "$0")/../bin" && pwd)"
# shellcheck source=tests/helpers.sh
source "$(dirname "$0")/helpers.sh"

make_workdir

cat >"$WORKDIR/state.json" <<'JSON'
{
  "values": {
    "root_module": {
      "resources": [
        {"type": "random_password", "name": "SENTRY_AUTH_TOKEN",
         "values": {"result": "sentry-secret"}},
        {"type": "random_password", "name": "GEOAPIFY_API_KEY",
         "values": {"result": "geoapify-secret"}},
        {"type": "random_password", "name": "db_admin_password",
         "values": {"result": "internal-secret"}},
        {"type": "aws_instance", "name": "SOMETHING_ELSE", "values": {"result": "not-a-var"}}
      ]
    }
  }
}
JSON

write_stub aws-vault <<'STUB'
#!/usr/bin/env bash
set -euo pipefail

# Called as: aws-vault exec PROFILE -- tofu <args>
shift 3
echo "$* [$(basename "$PWD")]" >> "$STUB_TOFU_LOG"

case "${2:-}" in
    show)
        cat "$STUB_STATE_JSON"
        ;;
    state)
        # Only the variables named in $STUB_EXISTING_VARS are already in the state.
        if [ "${3:-}" = "list" ]; then
            for existing in ${STUB_EXISTING_VARS:-}; do
                if [ "random_password.$existing" = "${4:-}" ]; then
                    echo "${4:-}"
                fi
            done
        fi
        ;;
esac
STUB

export STUB_STATE_JSON="$WORKDIR/state.json"
export STUB_TOFU_LOG="$WORKDIR/tofu.log"
export STUB_EXISTING_VARS=""

# An initialised directory, so the tools don't try to run "tofu init".
mkdir -p "$WORKDIR/project/.terraform"
cd "$WORKDIR/project"

expect "only upper case variables are listed" \
    $'SENTRY_AUTH_TOKEN=sentry-secret\nGEOAPIFY_API_KEY=geoapify-secret' \
    "$("$BINDIR/dev" tofu env)"

expect "a single variable can be fetched" \
    "geoapify-secret" "$("$BINDIR/dev" tofu env GEOAPIFY_API_KEY)"

if "$BINDIR/dev" tofu env NO_SUCH_VARIABLE >/dev/null 2>&1; then
    fail "asking for a missing env var should exit non-zero"
fi

if "$BINDIR/dev" tofu env db_admin_password >/dev/null 2>&1; then
    fail "tofu's internal passwords shouldn't be reachable as env vars"
fi

# Replacing a variable which is already in the state has to remove it before importing.
: >"$STUB_TOFU_LOG"
STUB_EXISTING_VARS="SENTRY_AUTH_TOKEN" \
    "$BINDIR/dev" tofu env set SENTRY_AUTH_TOKEN new-value >/dev/null
expect "replacing a variable removes it from the state, then imports it" \
    $'tofu state rm random_password.SENTRY_AUTH_TOKEN\ntofu import random_password.SENTRY_AUTH_TOKEN new-value' \
    "$(grep -E "state rm|import" "$STUB_TOFU_LOG" | sed -e 's/ \[.*\]$//')"

# A variable which isn't in the state yet is imported without a pointless removal.
: >"$STUB_TOFU_LOG"
"$BINDIR/dev" tofu env set BRAND_NEW_TOKEN new-value >/dev/null
expect "a brand new variable is imported without a state removal" \
    "tofu import random_password.BRAND_NEW_TOKEN new-value" \
    "$(grep -E "state rm|import" "$STUB_TOFU_LOG" | sed -e 's/ \[.*\]$//')"

# "all" visits directories holding a tofu.tf, and nothing else.
mkdir -p "$WORKDIR/repo/alpha/.terraform" "$WORKDIR/repo/beta/.terraform" "$WORKDIR/repo/modules"
touch "$WORKDIR/repo/alpha/tofu.tf" "$WORKDIR/repo/beta/tofu.tf"
cd "$WORKDIR/repo"

: >"$STUB_TOFU_LOG"
"$BINDIR/dev" tofu all plan >/dev/null
expect "every project directory is visited, and nothing else" \
    $'tofu plan [alpha]\ntofu plan [beta]' \
    "$(cat "$STUB_TOFU_LOG")"

finish "env vars listed, fetched and imported, and 'all' visits every project"
