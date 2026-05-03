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
      "tailscale"
      "lulu"
      "jordanbaird-ice"
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
    ];
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
    };
  };

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    stats
  ];

  system.stateVersion = 5;
}
