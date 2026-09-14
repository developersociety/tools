# Development

How to work on the tools themselves. For the house style, the shell conventions and how the tests
are put together, see [AGENTS.md](../AGENTS.md).

## Adding a tool

New tools go in `bin/` named `dev-something`, with a `# help: one line summary` comment near the
top. `dev help` picks them up automatically, and Homebrew installs anything matching `bin/dev*`,
so there's no list to keep in sync. Every command has a test in `tests/`, which stubs out the
commands it calls so it needs no credentials.

[AGENTS.md](../AGENTS.md) has the step by step: the script header, the `--help` guard, and how the
tests are put together.

## Tooling

The tools needed to work on this repo are shellcheck and shfmt. There's no virtualenv, because
there's no Python here:

```console
$ make install-local
$ make format
$ make check
```

`make check` runs shellcheck, checks the formatting, and then runs the tests, which is what CI
runs too. `make help` lists the targets.

## Testing locally

For day to day work, put the checkout on your `$PATH` and run the commands straight from it:

```console
$ export PATH="$PWD/bin:$PATH"
$ dev help
```

To test the Homebrew formula itself, tap the repo and check out the branch you want in the tap's
own clone. The formula builds from that clone, so whatever branch it's on is what gets installed
— nothing needs pushing to GitHub, and the formula needs no editing:

```console
$ brew tap developersociety/tools git@github.com:developersociety/tools.git
$ brew trust developersociety/tools

$ git -C "$(brew --repo developersociety/tools)" switch some-branch
$ brew fetch --force devtools
$ brew install devtools
$ brew test devtools
$ dev help
```

Then switch the tap clone back to `master` when you're done.

Two things to know. Homebrew clones committed state, so commit before installing — staged and
unstaged work is invisible to it, and a missing file shows up as a mysteriously incomplete
install rather than an error. And it caches the clone against the formula's `version`, so
`brew fetch --force devtools` is needed between installs of the same version.

To remove it again:

```console
$ brew uninstall devtools
$ brew untap developersociety/tools
```

Note that `brew uninstall` also sweeps up orphaned dependencies, so check what it reports before
walking away from it.

## Releasing

The tap and the tools are the same repo, so the formula builds from its own checkout. Homebrew
keys its cache on the `version` in `Formula/devtools.rb`, so shipping a release means bumping that
one line and pushing to `master`. Everyone picks it up on their next `brew upgrade`.
