# AGENTS.md

Notes for anyone — human or agent — working on this repo. The README covers installing and using the tools, `docs/`
covers the contributor workflow, and this covers writing the code.

## What this repo is

A Homebrew tap and the tools it installs, in one repo. `bin/dev` is a dispatcher: it finds its subcommands by globbing
for sibling `bin/dev-*` scripts, so adding a file is all it takes to add a command. There is no registry, no list of
commands, and no separate usage text to keep in step.

```
bin/dev              dispatcher: discovery, help, dispatch
bin/dev-*            one executable per command
tests/helpers.sh     shared assertions and stub scaffolding
tests/test-*.sh      one test script per commandÎ
Formula/devtools.rb  the Homebrew formula, which builds from this same checkout
Makefile             format, lint, test — the entry point for all of it
```

## Shell

Everything is bash: `#!/usr/bin/env bash` on every script, `# shellcheck shell=bash` on the sourced-only
`tests/helpers.sh`. Nothing uses a bash 4 feature, so the scripts run on the bash 3.2 that ships with macOS as well as
on a Homebrew bash. Keep it that way — no `mapfile`, no
`${var^^}`, no `declare -A`, no `<<<`, no process substitution.

Within bash, prefer the plain POSIX construct. The goal is that a reader who knows `sh` can follow any script here
without knowing bash's shorthand.

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
  For an exact match against one or two values, `if [ ... ] || [ ... ]` is shorter and reads better. Don't reach for
  `case` just to avoid repeating `"${1:-}"`.
- **No regex.** `=~` is bash-only and needs a second language in your head. A membership test is a space-wrapped
  `case` — the wrapping spaces are what make it an exact-word match, so `mainline`
  doesn't match `main`:
  ```bash
  case " $PROTECTED_BRANCHES $DEFAULT_BRANCH " in
  *" $BRANCH "*) continue ;;
  esac
  ```
- **No `$SECONDS`, `$RANDOM` or other bash magic variables.** A deadline is
  `$(($(date +%s) + $TIMEOUT))`.
- **Words over punctuation.** `source` rather than `.`, because a lone dot is easy to miss. The scripts are bash, so
  there is nothing to gain by spelling it the POSIX way.
- **Keep what earns its place.** Arrays, `local`, and `set -o pipefail` are bash-only and stay:
  rewriting them in POSIX makes the scripts longer and less safe, which defeats the point.

Deliberately unfollowable `source` lines get a directive with a reason, not a rule number —
`# shellcheck source=/dev/null  # path is set per-machine` rather than
`# shellcheck disable=SC1090`.

## Style

The house style is "least sugar, most explicit". Someone reading a script a year from now should not have to look
anything up.

- 100 character lines. Four-space indent, enforced by `shfmt --indent 4`.
- Every script opens with `set -euo pipefail` and `IFS=$'\n\t'`.
- Hard-coded values are named constants in `UPPER_CASE`, declared near the top of the file, above the logic that uses
  them. This holds during refactors too: if the mechanism consuming a constant changes, reshape the constant's value to
  suit — don't inline it and delete the name.
- Name your arguments. `REPO_ARG="$1"` once, then use the name, rather than `$1` scattered about.
- Prompt on the `read` that waits for it: `read -r -p "Press Enter to continue, or <ctrl>-c to
  bail"`, not an `echo` followed by a bare `read -r` that silently fills `$REPLY`.
- Descriptive names, and never a magic environment variable as a scratch variable. `WORK_DIR`, not
  `TMPDIR` — that one is read by `mktemp` and `git`, so assigning it moves everyone else's temporary files too.
- Comments explain *why*. The `# help:` block explains *what*, and it is the only user-facing documentation of a
  command.
- Anything creating a temporary directory cleans it up: `trap 'rm -rf "$WORK_DIR"' EXIT`.
- Anything destructive shows what it is about to do and waits for Enter first.

## Adding a command

1. Create `bin/dev-something`, `chmod +x`, with the standard header.
2. Give it a `# help:` block. The first line is the one-line summary in `dev help`; the whole block is what
   `dev help something` and `dev something --help` print.
3. Wire up `--help` with the standard guard, which re-enters the dispatcher rather than printing anything itself:
   ```bash
   if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
       exec "$(dirname "$0")/dev" help "${0##*/dev-}"
   fi
   ```
4. Write `tests/test-something.sh`.
5. Add a row to the table in `README.md`.

Homebrew installs everything matching `bin/dev*` and `dev help` globs for it, so there is nothing else to register.

## Tests

Plain bash scripts, no framework. One `tests/test-<command>.sh` per command, executable, run by
`make test`, which loops over `tests/test-*.sh` and stops at the first script to exit non-zero. Run one directly while
working on it: `./tests/test-clone.sh`.

Every test sources `tests/helpers.sh`, which provides:

- `make_workdir` — `mktemp -d` into `$WORKDIR` with an `EXIT` trap, and puts `$WORKDIR/stub` at the front of `$PATH`.
- `write_stub <name>` — writes an executable stub from stdin into the stub directory.
- `expect <description> <expected> <actual>` — exact-match assertion.
- `expect_contains <description> <haystack> <needle>` — substring assertion, which is what most output checks want.
- `fail <description>` — records a failure and carries on.
- `finish <summary>` — exits non-zero if anything failed, otherwise prints `PASS: <summary>`.

Assertions report and continue rather than aborting, so one run tells you everything that is broken instead of only the
first thing. That is why `finish` is what decides the exit status, and why every test must end with a `finish` line.

The commands here talk to git, ssh, pip, aws-vault, pyenv, `gh` and the 1Password CLI. Tests stub all of them with
`write_stub`, so they need no credentials, touch no real repos or servers, and write nothing outside their temporary
directory. A stub usually logs its arguments to a file the test then asserts against:

```bash
write_stub git <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
echo "$*" >> "$STUB_GIT_LOG"
STUB

export STUB_GIT_LOG="$WORKDIR/git.log"
```

Test the behaviour worth protecting — which arguments the command builds, which paths it writes, what it refuses to do,
and that it cleans up after a failure — rather than restating the implementation. Each test opens with a comment saying
what is worth checking in that command and why. Commands that wait for Enter are driven with `printf '\n' | ...`.

## Checks

`make check` — shellcheck, `shfmt --diff`, then the tests — is exactly what CI runs, so a green
`make check` locally means a green build. `make format` fixes the formatting it complains about. CI installs shfmt with
`go install`, because the GitHub runner image ships shellcheck but not shfmt.

## Docs

`docs/development.md` covers the contributor workflow: tooling, testing a branch through the Homebrew tap, and
releasing. `docs/tofu-env.md` explains the `dev tofu env` workflow. The README is deliberately limited to installation
and usage — new documentation goes in `docs/`.
