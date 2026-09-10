#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# dev-archive-repo pushes to a server and makes a GitHub repo read-only, so the interesting parts
# are that it aims at the right places and that it cleans up its temporary clone even when the
# push fails. Runs against stubbed git and gh.

BINDIR="$(cd "$(dirname "$0")/../bin" && pwd)"
# shellcheck source=tests/helpers.sh
source "$(dirname "$0")/helpers.sh"

make_workdir

write_stub git <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
echo "$*" >> "$STUB_GIT_LOG"
if [ "${1:-}" = "clone" ]; then
    mkdir -p "$4"
    exit 0
fi
if [ "${3:-}" = "push" ] && [ -n "${STUB_PUSH_FAILS:-}" ]; then
    echo "push refused" >&2
    exit 1
fi
if [ "${1:-}" = "-C" ]; then
    exit 0
fi
STUB

write_stub gh <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
echo "$*" >> "$STUB_GH_LOG"
STUB

export STUB_GIT_LOG="$WORKDIR/git.log"
export STUB_GH_LOG="$WORKDIR/gh.log"

# mktemp honours $TMPDIR, so pointing it somewhere known makes the cleanup checkable.
mkdir -p "$WORKDIR/tmp"
export TMPDIR="$WORKDIR/tmp"

count_temp_entries() {
    find "$TMPDIR" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' '
}

: >"$STUB_GIT_LOG"
: >"$STUB_GH_LOG"
printf '\n' | "$BINDIR/dev" archive-repo oldproject >/dev/null

expect "a bare name is assumed to be a developersociety repo" \
    "1" "$(grep -c "clone --bare git@github.com:developersociety/oldproject.git" "$STUB_GIT_LOG")"
expect "the mirror is pushed to the archive server" \
    "1" "$(grep -c "push --mirror git@smirkenorff.devsoc.org:archive/oldproject.git" "$STUB_GIT_LOG")"
expect "the repo is archived on GitHub afterwards" \
    "repo archive developersociety/oldproject --yes" "$(cat "$STUB_GH_LOG")"
expect "the temporary clone is cleaned up" "0" "$(count_temp_entries)"

: >"$STUB_GIT_LOG"
: >"$STUB_GH_LOG"
printf '\n' | "$BINDIR/dev" archive-repo someorg/theirproject >/dev/null
expect "an org/repo argument is used as given" \
    "1" "$(grep -c "clone --bare git@github.com:someorg/theirproject.git" "$STUB_GIT_LOG")"
expect "the archive path uses the repo name without the org" \
    "1" "$(grep -c "archive/theirproject.git" "$STUB_GIT_LOG")"

: >"$STUB_GH_LOG"
if printf '\n' | STUB_PUSH_FAILS=1 "$BINDIR/dev" archive-repo brokenproject >/dev/null 2>&1; then
    fail "a failed push should exit non-zero"
fi
expect "a failed push doesn't archive the repo on GitHub" "" "$(cat "$STUB_GH_LOG")"
expect "a failed push still cleans up the temporary clone" "0" "$(count_temp_entries)"

finish "mirrored and archived to the right places, and cleans up after a failure"
