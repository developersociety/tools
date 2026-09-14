# AGENTS.md

The rules for writing code in this repo. The README covers installing and using the tools, and
`docs/development.md` covers the contributor workflow — tooling, testing a branch and releasing.

`bin/dev` finds its subcommands by globbing for sibling `bin/dev-*` scripts, so a new executable
with a `# help:` block is a new command. There is no registry to update.

## Shell

Everything is bash: `#!/usr/bin/env bash` on every script, `# shellcheck shell=bash` on the
sourced-only `tests/helpers.sh`. Nothing uses a bash 4 feature, so the scripts run on the bash 3.2
that ships with macOS as well as on a Homebrew bash. Keep it that way — no `mapfile`, no
`${var^^}`, no `declare -A`, no `<<<`, no process substitution.

Within bash, prefer the plain POSIX construct. The goal is that a reader who knows `sh` can follow
any script here without knowing bash's shorthand.

- **`[ ]`, not `[[ ]]`.** Quote every variable inside it: `[ "$#" -ne 1 ]`, `[ -x "$script" ]`,
  `[ -n "${2:-}" ]`. Use the numeric operators (`-ne`, `-lt`, `-gt`) for numbers and `=` / `!=`
  for strings.
- **`case` only for patterns.** A glob or an alternation list is what `case` is for:
  ```bash
  case "$REPO_ARG" in
  */*) REPO_NAME="$REPO_ARG" ;;
  *) REPO_NAME="$DEFAULT_ORG/$REPO_ARG" ;;
  esac
  ```
  For an exact match against one or two values, `if [ ... ] || [ ... ]` is shorter and reads
  better. Don't reach for `case` just to avoid repeating `"${1:-}"`.
- **No regex.** `=~` is bash-only and needs a second language in your head. A membership test is a
  space-wrapped `case` — the wrapping spaces are what make it an exact-word match, so `mainline`
  doesn't match `main`:
  ```bash
  case " $PROTECTED_BRANCHES $DEFAULT_BRANCH " in
  *" $BRANCH "*) continue ;;
  esac
  ```
- **No `$SECONDS`, `$RANDOM` or other bash magic variables.** A deadline is
  `$(($(date +%s) + $TIMEOUT))`.
- **Words over punctuation.** `source` rather than `.`, because a lone dot is easy to miss. The
  scripts are bash, so there is nothing to gain by spelling it the POSIX way.
- **Keep what earns its place.** Arrays, `local`, and `set -o pipefail` are bash-only and stay:
  rewriting them in POSIX makes the scripts longer and less safe, which defeats the point.

Deliberately unfollowable `source` lines get a directive with a reason, not a rule number —
`# shellcheck source=/dev/null  # path is set per-machine` rather than
`# shellcheck disable=SC1090`.

## Style

The house style is "least sugar, most explicit". Someone reading a script a year from now should
not have to look anything up.

- 100 character lines. Four-space indent, enforced by `shfmt --indent 4`.
- Every script opens with `set -euo pipefail` and `IFS=$'\n\t'`.
- Hard-coded values are named constants in `UPPER_CASE`, declared near the top of the file, above
  the logic that uses them. This holds during refactors too: if the mechanism consuming a constant
  changes, reshape the constant's value to suit — don't inline it and delete the name.
- Name your arguments. `REPO_ARG="$1"` once, then use the name, rather than `$1` scattered about.
- Prompt on the `read` that waits for it: `read -r -p "Press Enter to continue, or <ctrl>-c to
  bail"`, not an `echo` followed by a bare `read -r` that silently fills `$REPLY`.
- Descriptive names, and never a magic environment variable as a scratch variable. `WORK_DIR`, not
  `TMPDIR` — that one is read by `mktemp` and `git`, so assigning it moves everyone else's
  temporary files too.
- Comments explain *why*. The `# help:` block explains *what*, and it is the only user-facing
  documentation of a command. Its first line is the summary in `dev help`.
- Anything creating a temporary directory cleans it up: `trap 'rm -rf "$WORK_DIR"' EXIT`.
- Anything destructive shows what it is about to do and waits for Enter first.

## Adding a command

`bin/dev-something`, `chmod +x`, standard header. Then: a `# help:` block, the `--help` guard
which re-enters the dispatcher rather than printing anything itself, a `tests/test-something.sh`,
and a row in the README's command table.

```bash
if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    exec "$(dirname "$0")/dev" help "${0##*/dev-}"
fi
```

## Tests

Plain bash, no framework. One executable `tests/test-<command>.sh` per command, sourcing
`tests/helpers.sh` for its assertions and stub scaffolding.

- Assertions report and carry on rather than aborting, so one run tells you everything that is
  broken. `finish` is what decides the exit status, so every test ends with a `finish` line.
- Stub every external command with `write_stub`, so tests need no credentials, touch no real repos
  or servers, and write nothing outside `$WORKDIR`. A stub usually logs its arguments to a file
  the test then asserts against.
- Test the behaviour worth protecting — which arguments the command builds, which paths it writes,
  what it refuses to do, and that it cleans up after a failure — rather than restating the
  implementation.
- Each test opens with a comment saying what is worth checking in that command and why.
- Commands that wait for Enter are driven with `printf '\n' | ...`.

## Docs

The README is deliberately limited to installation and usage. New documentation goes in `docs/`.
