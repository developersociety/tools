#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Checks that dev-clean-branches deletes merged and squash-merged branches while leaving
# unmerged and protected ones alone. Squash-merge detection is the only non-obvious logic in
# these tools, and it silently does nothing when it breaks.

CLEAN_BRANCHES="$(cd "$(dirname "$0")/../bin" && pwd)/dev-clean-branches"
# shellcheck source=tests/helpers.sh
source "$(dirname "$0")/helpers.sh"

make_workdir

export GIT_AUTHOR_NAME="Test" GIT_AUTHOR_EMAIL="test@example.com"
export GIT_COMMITTER_NAME="Test" GIT_COMMITTER_EMAIL="test@example.com"

git init --quiet --bare --initial-branch=main "$WORKDIR/origin.git"
git clone --quiet "$WORKDIR/origin.git" "$WORKDIR/repo" 2>/dev/null
cd "$WORKDIR/repo"

echo "start" >file.txt
git add file.txt
git commit --quiet -m "Initial commit"
git push --quiet origin main

git switch --quiet -c merged-branch
echo "merged" >merged.txt
git add merged.txt
git commit --quiet -m "Merged work"

git switch --quiet -c squashed-branch main
echo "squashed one" >squashed.txt
git add squashed.txt
git commit --quiet -m "Squashed work, part one"
echo "squashed two" >>squashed.txt
git commit --quiet -am "Squashed work, part two"

git switch --quiet -c unmerged-branch main
echo "unmerged" >unmerged.txt
git add unmerged.txt
git commit --quiet -m "Unmerged work"

git switch --quiet main
git merge --quiet --no-ff -m "Merge merged-branch" merged-branch >/dev/null
git merge --quiet --squash squashed-branch >/dev/null 2>&1
git commit --quiet -m "Squash merge of squashed-branch"
git push --quiet origin main

"$CLEAN_BRANCHES" --yes >/dev/null

expect "merged and squash-merged branches go, the unmerged one stays" \
    "main unmerged-branch " "$(git branch --format "%(refname:short)" | sort | tr '\n' ' ')"

# A second run has nothing to delete, which used to abort the script when grep found no matches.
git switch --quiet main
git branch --quiet -D unmerged-branch
SECOND_RUN=$("$CLEAN_BRANCHES" --yes)

if [[ $SECOND_RUN != *"No local branches need removing"* ]]; then
    fail "expected a clean repo to report nothing to remove, got: $SECOND_RUN"
fi

finish "merged and squash-merged branches removed, and a clean repo says so"
