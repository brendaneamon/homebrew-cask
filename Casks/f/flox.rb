cask "flox" do
  arch arm: "aarch64", intel: "x86_64"

  version "1.14.0"
  sha256 arm:   "cb09a2c152b66231b76828851ef3e8ae6439b4a32e44ff3eb7bdc203f71cddef",
         intel: "770fa9ebf06296b08fd8a9d2f75a2440da6a29f6795cb046d2041fd0532109b9"

  url "https://downloads.flox.dev/by-env/stable/osx/flox-#{version}.#{arch}-darwin.pkg"
  name "flox"
  desc "Manages environments across the software lifecycle"
  homepage "https://flox.dev/"

  livecheck do
    url "https://downloads.flox.dev/by-env/stable/LATEST_VERSION"
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  depends_on :macos

  pkg "flox-#{version}.#{arch}-darwin.pkg"

  # Refuse to install over an existing Nix installation that Flox does not manage.
  preflight_steps do
    if_path_exists "/nix/var/nix/db/db.sqlite" do
      unless_path_exists "/etc/flox-version" do
        unless_path_exists "/etc/flox-version.update" do
          run "/bin/sh", args: ["-c", <<~EOS]
            cat >&2 <<'MSG'
            An existing Nix installation was found at /nix.

            Installing Flox over that installation will replace the Nix daemon
            and remove Nix from the default system profile. Installation via
            Homebrew does not support this.

            To install Flox on a machine with an existing Nix installation, see
            https://flox.dev/docs/install-flox
            MSG
            exit 1
          EOS
        end
      end
    end
  end

  uninstall launchctl: [
              "org.nixos.darwin-store",
              "org.nixos.nix-daemon",
            ],
            quit:      [
              "org.nixos.darwin-store",
              "org.nixos.nix-daemon",
            ],
            script:    {
              executable: "/usr/local/share/flox/scripts/uninstall",
              sudo:       true,
            },
            pkgutil:   "com.floxdev.flox"

  zap script: {
        executable: "/usr/local/share/flox/scripts/uninstall_zap",
        args:       ["--zap"],
        sudo:       true,
      },
      trash:  [
        "/etc/flox-version.update",
        "/etc/nix/nix.conf.bak",
        "/usr/local/share/flox/scripts/uninstall_zap",
        "~/.cache/flox",
        "~/.config/flox",
        "~/.local/share/flox",
        "~/.local/state/flox",
      ]
end
