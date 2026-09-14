#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# dev-tofu runs tofu under a specific AWS profile. The profile is the part worth pinning down,
# since the wrong one points tofu at the wrong account. Runs against a stubbed aws-vault.

BINDIR="$(cd "$(dirname "$0")/../bin" && pwd)"
# shellcheck source=tests/helpers.sh
source "$(dirname "$0")/helpers.sh"

make_workdir

write_stub aws-vault <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
echo "$*"
STUB

expect "tofu runs under the devsoc-tofu profile" \
    "exec devsoc-tofu -- tofu plan" "$("$BINDIR/dev" tofu plan)"

expect "tofu's own arguments are passed through untouched" \
    "exec devsoc-tofu -- tofu apply -auto-approve" \
    "$("$BINDIR/dev" tofu apply -auto-approve)"

finish "tofu runs under the right profile, with its arguments intact"
