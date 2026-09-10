# The Developer Society — Development Tools

Tools for making development at The Developer Society quicker, easier and less error prone.

<https://github.com/developersociety/tools>

## Installation

The tools are distributed through our own Homebrew tap. The repo is private, so Homebrew fetches
it over SSH using the GitHub key you already have set up:

```console
$ brew tap developersociety/tools git@github.com:developersociety/tools.git
$ brew trust developersociety/tools
$ brew install devtools
```

The explicit git URL is required: without it Homebrew guesses a public
`https://github.com/developersociety/homebrew-tools` and gets a 404. `brew trust` is required
too, as Homebrew refuses to load formulae from third-party taps until you say so.

If you previously added a checkout of this repo to your `$PATH`, remove that from your shell
profile. It shadows the Homebrew copies, and you'll keep running the old scripts without
noticing — `brew install` warns about this, but the warning is easy to scroll past.

To upgrade later:

```console
$ brew upgrade devtools
```

Every tool is also available as its own command, so `dev clone devsoc` and `dev-clone devsoc` do
the same thing.

## Usage

Run `dev help` for the list of commands, and `dev help <command>` for the detail on one of them.
Each command also takes `--help` directly:

```console
$ dev help
$ dev help tofu
$ dev tofu --help
```

Each command explains itself, so the list below is a map rather than a manual — run
`dev help <command>` for the detail.

| Command | What it does |
| --- | --- |
| `dev clone` | Clone a repo and set up virtualenvwrapper for it |
| `dev clean-branches` | Delete merged local branches, squash-merges included, and prune remotes |
| `dev tofu` | Run tofu with the devsoc-tofu profile, and manage project env vars |
| `dev aws-login` | Open the AWS console via aws-vault |
| `dev update-aws-config` | Rewrite `~/.aws/config` from the 1Password template |
| `dev unlock-server` | Unlock the encrypted root filesystem on one or more servers |
| `dev archive-repo` | Mirror a repo to the archive server, then archive it on GitHub |
| `dev wipeenv` | Uninstall every package in the active virtualenv |

### dev tofu env

The one command worth explaining outside its own help, because the workflow behind it isn't
obvious. A project's environment variables live in the tofu state as `random_password` resources
declared in the project's `envvars.tf`. Reading and setting them used to mean copy-pasting raw
`tofu show -json | jq ...` and `state rm` / `import` incantations from the comments at the top of
each `envvars.tf`:

```console
$ dev tofu env                          # list every variable and its value
$ dev tofu env SENTRY_AUTH_TOKEN        # print one value
$ dev tofu env set SENTRY_AUTH_TOKEN    # prompt for the value, then import it
```

Setting a variable removes it from the state and re-imports it, so a `dev tofu apply` is still
needed to get the new value onto the running service. The variable has to have a
`random_password` resource in `envvars.tf` before it can be imported, and variables are told
apart from tofu's internal passwords by their upper case names.

## Development

Please contribute! If you find yourself needing to do the same thing over and over, or you keep
forgetting a process, or you just feel you're typing too much to do boring stuff... then create a
script to automate/help/optimise it. And then we can all benefit.

New tools go in `bin/` named `dev-something`, with a `# help: one line summary` comment near the
top. `dev help` picks them up automatically, and Homebrew installs anything matching `bin/dev*`,
so there's no list to keep in sync.

New commands are documented in the comment block starting at their `# help:` line. `dev help`
prints the first line in its summary list, `dev help <command>` prints the whole block, and each
script's `--help` prints the same thing, so there's only ever one copy of the usage text.

The tools needed to work on this repo are shellcheck and shfmt. There's no virtualenv, because
there's no Python here:

```console
$ make install-local
$ make format
$ make check
```

`make check` runs shellcheck, checks the formatting, and then runs the tests, which is what CI
runs too. `make help` lists the targets.

### Testing locally

For day to day work, put the checkout on your `$PATH` and run the commands straight from it:

```console
$ export PATH="$PWD/bin:$PATH"
$ dev help
```

To test the Homebrew formula itself, tap your own checkout. Homebrew clones committed state, and
the formula fetches from GitHub, so point it at your working copy first and commit that change
locally — don't push it:

```console
$ sed -i '' "s|git@github.com:developersociety/tools.git|file://$PWD|" Formula/devtools.rb
$ git commit -am "Local formula test"

$ brew tap local/tools "$PWD"
$ brew trust local/tools
$ brew install local/tools/devtools
$ dev help
```

Then put it back:

```console
$ brew uninstall devtools
$ brew untap local/tools
$ git reset --hard HEAD~1
```

Note that `brew uninstall` also sweeps up orphaned dependencies, so check what it reports before
walking away from it.

Every command has a test in `tests/`. They stub out git, ssh, pip, aws-vault, pyenv and the
1Password CLI, so they need no credentials and touch nothing outside a temporary directory.

### Releasing

Homebrew keys its cache on the `version` in `Formula/devtools.rb`, so shipping a release means
bumping that one line and pushing to `master`. Everyone picks it up on their next `brew upgrade`.
