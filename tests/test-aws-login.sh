#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# dev-aws-login only picks a profile, but getting that wrong logs you into the wrong AWS account.

BINDIR="$(cd "$(dirname "$0")/../bin" && pwd)"
# shellcheck source=tests/helpers.sh
source "$(dirname "$0")/helpers.sh"

make_workdir

write_stub aws-vault <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
echo "$*"
STUB

expect "no arguments uses the default profile" \
    "login -- devsoc" "$(
        unset AWS_VAULT_PROFILE
        "$BINDIR/dev" aws-login
    )"

expect "AWS_VAULT_PROFILE overrides the default" \
    "login -- someotherprofile" "$(AWS_VAULT_PROFILE=someotherprofile "$BINDIR/dev" aws-login)"

expect "an explicit profile wins over everything" \
    "login -- explicitprofile" \
    "$(AWS_VAULT_PROFILE=someotherprofile "$BINDIR/dev" aws-login explicitprofile)"

finish "the right aws-vault profile is chosen"
