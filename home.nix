{ config, pkgs, ... }:

{
  home.username = "fahimalizain";
  home.homeDirectory = "/home/fahimalizain";

  # Packages for user
  home.packages = with pkgs; [
    kdePackages.kate
  ];

  # Git configuration
  programs.git = {
    enable = true;
    userName = "Fahim Ali Zain";
    userEmail = "fahimalizain@gmail.com";
  };

  # npm global packages directory (NixOS requires non-nix-store location)
  home.file.".npm-global/.keep".text = "";

  # Bash configuration - migrated from .bashrc
  programs.bash = {
    enable = true;
    bashrcExtra = ''
      export SSH_AUTH_SOCK="/home/fahimalizain/.1password/agent.sock"
      # NixOS config location (override if repo is elsewhere)
      export NIXOS_CONFIG="''${NIXOS_CONFIG:-$HOME/nixos-config}"
      # npm global packages (NixOS-compatible)
      export NPM_CONFIG_PREFIX="$HOME/.npm-global"
      export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"
    '';
    shellAliases = {
      nrs = "$NIXOS_CONFIG/scripts/hook_prebuild.sh && sudo nixos-rebuild switch --flake $NIXOS_CONFIG#thinkpad-nixos";
      nrb = "$NIXOS_CONFIG/scripts/hook_prebuild.sh && sudo nixos-rebuild build --flake $NIXOS_CONFIG#thinkpad-nixos";
    };
  };

  # This value determines the Home Manager release
  home.stateVersion = "25.11";
}
