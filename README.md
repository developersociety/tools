# The Developer Society — Development Tools

Tools for making development at The Developer Society quicker, easier and less error-prone.

## Installation

The tools are distributed through our own Homebrew tap. The repo is private, so Homebrew fetches it over SSH using the
GitHub key you already have set up:

```console
$ brew tap developersociety/tools git@github.com:developersociety/tools.git
$ brew trust developersociety/tools
$ brew install devtools
```

The explicit git URL is required: without it Homebrew guesses a public
`https://github.com/developersociety/homebrew-tools` and gets a 404. `brew trust` is required too, as Homebrew refuses
to load formulae from third-party taps until you say so.

If you previously added a checkout of this repo to your `$PATH`, remove that from your shell profile. It shadows the
Homebrew copies, and you'll keep running the old scripts without noticing.

To upgrade later:

```console
$ brew upgrade devtools
```

## Usage

Run `dev help` for the list of commands, and `dev help <command>` for the detail on one of them. Each command also takes
`--help` directly, and is available under its own name, so `dev clone devsoc` and `dev-clone devsoc` do the same thing.

```console
$ dev help
$ dev help tofu
$ dev tofu --help
```

Each command explains itself, so the list below is a map rather than a manual.

| Command                 | What it does                                                            |
|-------------------------|-------------------------------------------------------------------------|
| `dev clone`             | Clone a repo and set up virtualenvwrapper for it                        |
| `dev clean-branches`    | Delete merged local branches, squash-merges included, and prune remotes |
| `dev tofu`              | Run tofu with the devsoc-tofu profile, and manage project env vars      |
| `dev aws-login`         | Open the AWS console via aws-vault                                      |
| `dev update-aws-config` | Rewrite `~/.aws/config` from the 1Password template                     |
| `dev unlock-server`     | Unlock the encrypted root filesystem on one or more servers             |
| `dev archive-repo`      | Mirror a repo to the archive server, then archive it on GitHub          |
| `dev wipeenv`           | Uninstall every package in the active virtualenv                        |

Managing a project's environment variables has a workflow of its own — see
[docs/tofu-env.md](docs/tofu-env.md).

## Development

Please contribute! If you find yourself needing to do the same thing over and over, or you keep forgetting a process, or
you just feel you're typing too much to do boring stuff ... then create a script to automate/help/optimise it. And then
we can all benefit.

See [docs/development.md](docs/development.md) to get set up, and [AGENTS.md](AGENTS.md) for the house style and how the
tests are put together.
