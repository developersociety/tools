# The tap and the tools are the same repo, so the scripts are already on disk next to this
# formula: Homebrew builds from the tap's own checkout rather than fetching from GitHub again.
# That also makes testing a branch a matter of checking it out in the tap, with no push needed.

class Devtools < Formula
  desc "Development tools for The Developer Society"
  homepage "https://github.com/developersociety/tools"

  # A pinned revision would need a second commit after every tag, so the version is what Homebrew
  # keys its cache on: bump it to ship a release. While testing a branch, "brew fetch --force
  # devtools" clears the cached clone without a bump.
  TAP_CHECKOUT = Pathname.new(__dir__).parent.freeze

  # No "branch:" here - cloning a local repo follows its HEAD, which is whichever branch the tap
  # is currently on, which is exactly what testing a branch needs.
  url "file://#{TAP_CHECKOUT}", using: :git
  version "1.0.0"

  depends_on "aws-vault"
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
