{ config, pkgs, inputs, ... }:

{
  imports = [
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
    brews = [
      "opencode"
    ];
    casks = [
      "tailscale-app"
      "lulu"
      "jordanbaird-ice@beta"
      "rustdesk"
      "1password"
      "1password-cli"
      "google-chrome"
      "opencode-desktop"
      "visual-studio-code"
      "slack"
      "whatsapp"
      "spotify"
      "cloudflare-warp"
      "docker-desktop"
      "shottr"
      "stats"
      "ghostty"
      "openscad@snapshot"
    ];
    onActivation = {
      autoUpdate = true;
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
  ];

  system.stateVersion = 5;
}
