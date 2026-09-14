#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Checks that dev-clean-branches deletes merged branches while leaving unmerged and protected
# ones alone, and that a repo with nothing to delete says so rather than falling over.

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

git switch --quiet -c unmerged-branch main
echo "unmerged" >unmerged.txt
git add unmerged.txt
git commit --quiet -m "Unmerged work"

git switch --quiet main
git merge --quiet --no-ff -m "Merge merged-branch" merged-branch >/dev/null
git push --quiet origin main

printf '\n' | "$CLEAN_BRANCHES" >/dev/null

expect "the merged branch goes, the unmerged one stays" \
    "main unmerged-branch " "$(git branch --format "%(refname:short)" | sort | tr '\n' ' ')"

# A second run has nothing to delete, which used to abort the script when grep found no matches.
git branch --quiet -D unmerged-branch
SECOND_RUN=$(printf '\n' | "$CLEAN_BRANCHES")

expect_contains "expected a clean repo to report nothing to remove" \
    "$SECOND_RUN" "No local branches need removing"

finish "merged branches removed, protected ones kept, and a clean repo says so"
