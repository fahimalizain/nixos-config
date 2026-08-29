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
      "nikitabobko/tap"
      "agentwrapper/tap"
    ];
    brews = [
      "agent-browser"
      "awscli"
      "azure-cli"
      "bazelisk"
      "buildifier"
      "cloudflare-wrangler"
      "herdr"         # terminal workspace manager for AI coding agents (bottled)
      "node"          # system Node/npm (openchamber CLI + general use)
      "nvm"           # per-project Node versions; not used for openchamber
      "opencode"
      "rclone"
      "scrcpy"
      { name = "openjdk@21"; link = true; }
    ];
    casks = [
      "esengine/reasonix/reasonix"
      "tailscale-app"
      "lulu"
      "jordanbaird-ice@beta"
      "rustdesk"
      "1password"
      "1password-cli"
      "claude-code"
      "google-chrome"
      "grok-build"
      "iina"
      "opencode-desktop"
      "visual-studio-code"
      "slack"
      "discord"
      "whatsapp"
      "spotify"
      "sony-ps-remote-play"
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
      "openchamber"          # macOS desktop GUI app (different from the @openchamber/web CLI in home.nix)
      "cursor"
      "crossover"
      "android-studio"
      "android-platform-tools"
      "aerospace"
      "raycast"
      "wezterm"
      "agentwrapper/tap/agent-orchestrator"  # desktop supervisor for parallel coding agents
      "block-buzz"
    ];
    onActivation = {
      autoUpdate = true;
      # NOTE: `zap` runs `brew bundle cleanup` after `brew bundle`, which
      # internally calls `brew cleanup`.  If that sub-step exits non-zero
      # (e.g. stale cache files, empty directories under /opt/homebrew/lib)
      # the entire activation script can abort *before* home-manager
      # activation runs.  When `nrs` ends without the expected
      # "Activating home-manager configuration" line, re-run it
      # on a clean state or temporarily switch to `cleanup = "uninstall"`.
      cleanup = "zap";
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
    tmux
  ];


  system.defaults.dock = {
    # Top-left hot corner -> Mission Control
    wvous-tl-corner = 2;
    # Top-right hot corner -> Mission Control
    wvous-tr-corner = 2;
  };

  # Third-party taps (esengine/reasonix, nikitabobko/tap) need explicit
  # trust before `brew bundle` runs, otherwise `command-not-found` and
  # other brew commands will prompt.  Without `--force-cleanup`, `zap`
  # preserves tap state across rebuilds, so a single `mkBefore` trust is
  # enough.
  system.activationScripts.homebrew.text = lib.mkBefore ''
    ${lib.concatMapStrings (tap: ''
      echo "trusting ${tap.name} tap..." >&2
      sudo -u ${lib.escapeShellArg config.homebrew.user} --set-home /opt/homebrew/bin/brew trust ${tap.name} 2>/dev/null || true
    '') config.homebrew.taps}
  '';

  system.stateVersion = 5;

  # This only adds Zero Trust hosts entries to /etc/hosts.
  # Cloudflare WARP itself is installed via the `cloudflare-warp` brew cask above.
  my_services.cloudflare = {
    zerotrust.fahimalizain.enable = true;
    tunnel.enable = true;  # Installs cloudflared for ngrok-like tunnels
  };
}
