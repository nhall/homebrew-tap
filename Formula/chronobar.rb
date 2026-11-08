# Source of truth for the formula in the nhall/homebrew-tap repo (Formula/chronobar.rb).
# On each release: tag vX.Y.Z, update `tag` and `revision` here, and copy this file to the tap.
# The source is cloned with git rather than downloaded as a tarball, so it installs while the
# repository is private: git authenticates with the installer's own GitHub credentials.
class Chronobar < Formula
  desc "Menu bar time tracker with labelled timers that agents can drive"
  homepage "https://github.com/nhall/chronobar"
  url "https://github.com/nhall/chronobar.git",
      tag:      "v2.0.1",
      revision: "6bb40ed6f479645a847e5d62e58e1049e28ce3e8"
  license "MIT"
  head "https://github.com/nhall/chronobar.git", branch: "main"

  # Builds with the Swift toolchain from the Command Line Tools; Xcode is not required.
  # Needs Swift 6.0 or later (Package.swift's tools version, and the MCP SDK's floor):
  # Command Line Tools 16 or later. SwiftPM stops with "requires a minimum Swift tools version"
  # on an older toolchain.
  depends_on macos: :sonoma

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
