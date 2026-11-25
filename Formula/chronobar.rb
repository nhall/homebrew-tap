# Source of truth for the formula in the nhall/homebrew-tap repo (Formula/chronobar.rb).
# On each release: tag vX.Y.Z, update `tag` and `revision` here, and copy this file to the tap.
# The source is cloned with git at the release tag rather than downloaded as a tarball; see
# docs/adr/0008-public-tap-keeps-cloning-at-the-release-tag.md.
class Chronobar < Formula
  desc "Menu bar time tracker with labelled timers that agents can drive"
  homepage "https://github.com/nhall/chronobar"
  url "https://github.com/nhall/chronobar.git",
      tag:      "v2.3.0",
      revision: "7078e53d15fbc0303fe5fa41f285999e3229d707"
  license "MIT"
  head "https://github.com/nhall/chronobar.git", branch: "main"

  # Builds with the Swift toolchain from the Command Line Tools; Xcode is not required.
  # Needs Swift 6.1 or later (the MCP SDK's code): Command Line Tools 16.3 or later, which need
  # macOS 15.2. An older toolchain stops with a compile error in the SDK. Homebrew can only require
  # Sequoia, not 15.2; the install docs say 15.2.
  depends_on macos: :sequoia

  def install
    # SwiftPM's own sandbox can't nest inside Homebrew's, and it fetches the packages pinned by
    # Package.resolved (KeyboardShortcuts, the MCP SDK and its dependencies) during the build.
    ENV["SWIFT_BUILD_FLAGS"] = "--disable-sandbox"
    ENV["VERSION"] = version.to_s
    system "scripts/bundle-app.sh", "build"
    prefix.install "build/Chronobar.app"
    # `chronobar` launches the app beside it (../Chronobar.app from the keg's bin), so it finds this
    # version's app without Launch Services having seen it.
    bin.install "build/bin/chronobar"
  end

  def caveats
    <<~EOS
      Chronobar.app is in #{opt_prefix}. To open it from Spotlight, Launchpad or Finder:
        ln -sfn #{opt_prefix}/Chronobar.app ~/Applications/Chronobar.app
      The link points at Homebrew's "opt" path, so it keeps working after `brew upgrade`.

      For agents, register `chronobar mcp` as a stdio MCP server; docs/connecting-agents.md in
      #{homepage} has each client's setup.
    EOS
  end

  test do
    app = prefix/"Chronobar.app"
    assert_predicate app/"Contents/MacOS/Chronobar", :executable?
    system "codesign", "--verify", "--deep", "--strict", app
    system "codesign", "--verify", "--strict", bin/"chronobar"
    assert_match "Usage: chronobar", shell_output("#{bin}/chronobar help")
  end
end
