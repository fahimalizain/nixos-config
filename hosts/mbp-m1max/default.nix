{ config, pkgs, inputs, lib, ... }:

{
  imports = [
    ../../modules/services/cloudflare.nix
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  nix.package = pkgs.lix;

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    always-allow-substitutes = true;
    trusted-substituters = [ "https://cache.lix.systems" ];
    trusted-public-keys = [ "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o=" ];
    extra-nix-path = [ "nixpkgs=flake:nixpkgs" ];
  };

  users.users.fahimalizain.home = "/Users/fahimalizain";

  system.primaryUser = "fahimalizain";

  homebrew = {
    enable = true;
    taps = [
      "esengine/reasonix"
    ];
    brews = [
      "opencode"
      "node@24"
    ];
    casks = [
      "esengine/reasonix/reasonix"
      "tailscale-app"
      "lulu"
      "jordanbaird-ice@beta"
      "rustdesk"
      "1password"
      "1password-cli"
      "google-chrome"
      "grok-build"
      "opencode-desktop"
      "visual-studio-code"
      "slack"
      "discord"
      "whatsapp"
      "spotify"
      "obsidian"
      "cloudflare-warp"
      "conductor"
      "docker-desktop"
      "shottr"
      "stats"
      "keepingyouawake"
      "ghostty"
      "openscad@snapshot"
      "utm"
      "antigravity"
      "kicad"
      "linearmouse"
      "openchamber"
      "crossover"
    ];
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      extraFlags = [ "--force-cleanup" ];
    };
  };

  nixpkgs.config.allowUnfree = true;

  nixpkgs.overlays = [
    (final: prev: {
      # direnv shell integration tests crash on macOS with Killed: 9 (SIGKILL).
      # Tracked upstream: https://github.com/NixOS/nixpkgs/issues/507531
      # Caused by libarchive 3.8.4 -> 3.8.6 update breaking fish/zsh tests.
      # Only run Go unit tests; skip all shell-specific tests.
      direnv = prev.direnv.overrideAttrs (old: {
        checkPhase = ''
          runHook preCheck
          make -j$NIX_BUILD_CORES test-go
          runHook postCheck
        '';
      });
    })
  ];

  environment.systemPackages = with pkgs; [
    python312
    poetry
    uv
    gh
  ];

  # Ensure node@24 is found before the default Homebrew node (v26, installed as a dependency of opencode).
  # This affects GUI apps like VSCode.
  environment.systemPath = [ "/opt/homebrew/opt/node@24/bin" ];

  system.defaults.dock = {
    # Top-left hot corner -> Mission Control
    wvous-tl-corner = 2;
    # Top-right hot corner -> Mission Control
    wvous-tr-corner = 2;
  };

  # esengine/reasonix requires explicit trust for its packages.
  # With cleanup = "zap", the tap gets re-added fresh each cycle losing trust,
  # so re-assert it as the same user that `brew bundle` runs as, right before
  # the bundle command. We prepend to the homebrew activation script's `text`
  # (a `types.lines` option) using `mkBefore` so it runs first. The activation
  # script runs as root, but brew stores trust per-user in ~/.homebrew/trust.json,
  # so we must `sudo -u` to the same user `brew bundle` will run as.
  system.activationScripts.homebrew.text = lib.mkBefore ''
    echo "trusting esengine/reasonix tap..." >&2
    sudo -u ${lib.escapeShellArg config.homebrew.user} --set-home /opt/homebrew/bin/brew trust esengine/reasonix 2>/dev/null || true
  '';

  system.stateVersion = 5;

  # This only adds Zero Trust hosts entries to /etc/hosts.
  # Cloudflare WARP itself is installed via the `cloudflare-warp` brew cask above.
  my_services.cloudflare = {
    zerotrust.fahimalizain.enable = true;
    tunnel.enable = true;  # Installs cloudflared for ngrok-like tunnels
  };
}
