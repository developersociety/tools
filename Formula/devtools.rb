class Devtools < Formula
  desc "Development tools for The Developer Society"
  homepage "https://github.com/developersociety/tools"

  # The tap and the tools share one repo, so a pinned revision would need a second commit after
  # every tag. Instead the version is what Homebrew keys its cache on: bump it to ship a release,
  # and Homebrew refetches master.
  url "git@github.com:developersociety/tools.git", using: :git, branch: "master"
  version "1.0.0"

  depends_on "aws-vault"
  depends_on "awscli"
  depends_on "gh"
  depends_on "jq"
  depends_on "opentofu"

  # The 1Password CLI is a cask, which formulae can't depend on, and pyenv/virtualenvwrapper are
  # only needed by "dev clone". The scripts which need them say so when they're missing.

  def install
    bin.install Dir["bin/dev*"]
  end

  test do
    assert_match "Usage: dev <command>", shell_output("#{bin}/dev help")
  end
end
