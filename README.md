# The Developer Society - Development Tools

Tools for making development at The Developer Society quicker, easier and less error prone.

## Installation

Clone the repo:

```console
$ git clone git@github.com:developersociety/tools.git
```

Then add its `bin` directory to your `$PATH`, by adding this to your `~/.zshrc`:

```bash
export PATH="/path/to/tools/bin:$PATH"
```

To update the tools later, `git pull` in the checkout.

## Usage

Every tool takes `--help`, which prints its usage and what it does:

```console
$ dev-clone --help
```

| Command                 | What it does                                        | Needs                           |
|-------------------------|-----------------------------------------------------|---------------------------------|
| `dev-clone`             | Clone a repo and set up virtualenvwrapper for it    | virtualenvwrapper, pyenv        |
| `dev-clean-branches`    | Delete merged local branches and prune remotes      |                                 |
| `dev-wipeenv`           | Uninstall every package in the active virtualenv    |                                 |
| `dev-tofu`              | Run tofu with the devsoc-tofu AWS profile           | aws-vault, opentofu             |
| `dev-aws-login`         | Open the AWS console via aws-vault                  | aws-vault                       |
| `dev-update-aws-config` | Rewrite `~/.aws/config` from the 1Password template | 1Password CLI (`op`)            |
| `dev-unlock-server`     | Unlock the encrypted root filesystem on a server    | 1Password CLI (`op`)            |
| `dev-archive-repo`      | Mirror a repo to the archive server                 |                                 |

To work on the tools themselves, see [docs/development.md](docs/development.md).
