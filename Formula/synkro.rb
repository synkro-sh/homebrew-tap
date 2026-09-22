# Maintained for the v0.2.0-rc.5 release. The automated generator that lived in
# synkro-sh/synkro-rs was dropped in the event-sourced refactor; until it is
# rebuilt (SYN-481) this formula is updated by hand — bump `version`, the three
# urls, and their sha256 together from the release's SHA256SUMS.

class Synkro < Formula
  desc "Local policy enforcement engine for AI coding agents"
  homepage "https://github.com/synkro-sh/synkro-rs"
  version "0.2.0-rc.5"

  depends_on "restatedev/tap/restate-server"

  on_macos do
    depends_on arch: :arm64

    on_arm do
      url "https://github.com/synkro-sh/homebrew-tap/releases/download/v0.2.0-rc.5/synkro-aarch64-apple-darwin.tar.gz"
      sha256 "c2ba9658f7a3f0bfae40e6bd8d3ceba8d05d9daac841f03f1338efc89cb185a3"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/synkro-sh/homebrew-tap/releases/download/v0.2.0-rc.5/synkro-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "512d904f1e4af7ed0f0c35e70a279595e65177cdf7b9c9dce67bee72f9c27b9f"
    end
    on_intel do
      url "https://github.com/synkro-sh/homebrew-tap/releases/download/v0.2.0-rc.5/synkro-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "68da10af6d4bfa3d1e31895f4f9887ca013771989abcd9974ff9b99f212831a8"
    end
  end

  def install
    bin.install "synkro"
  end

  test do
    assert_match "synkro", shell_output("#{bin}/synkro --version")
  end
end
