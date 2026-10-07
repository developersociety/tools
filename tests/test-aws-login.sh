#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# dev-aws-login only hands its arguments to aws-vault, but getting that wrong logs you into the
# wrong AWS account.

BINDIR="$(cd "$(dirname "$0")/../bin" && pwd)"
# shellcheck source=tests/helpers.sh
source "$(dirname "$0")/helpers.sh"

make_workdir

write_stub aws-vault <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
echo "$*"
STUB

expect "the profile is passed through to aws-vault" \
    "login -- someprofile" "$("$BINDIR/dev" aws-login someprofile)"

finish "the profile reaches aws-vault untouched"
