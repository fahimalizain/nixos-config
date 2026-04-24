{ config, pkgs, pkgs-unstable, hostname, ... }:

{
  # Common packages for all hosts
  home.packages = with pkgs; [
    # Add shared packages here
  ];

  # Git configuration
  programs.git = {
    enable = true;
    settings.user = {
      name = "Fahim Ali Zain";
      email = "fahimalizain@gmail.com";
    };
  };

  # npm global packages directory (NixOS requires non-nix-store location)
  home.file.".npm-global/.keep".text = "";

  # Enable bash shell (required for login)
  programs.bash.enable = true;

  # Shell configuration (generic - applies to all enabled shells)
  home.sessionVariables = {
    # npm global packages (NixOS-compatible)
    NPM_CONFIG_PREFIX = "$HOME/.npm-global";
  };

  home.sessionPath = [ "$NPM_CONFIG_PREFIX/bin" ];

  home.shellAliases = {
    nrs = "$NIXOS_CONFIG/scripts/hook_prebuild.sh && sudo nixos-rebuild switch --flake $NIXOS_CONFIG#${hostname}";
    nrb = "$NIXOS_CONFIG/scripts/hook_prebuild.sh && sudo nixos-rebuild build --flake $NIXOS_CONFIG#${hostname}";
  };

  # This value determines the Home Manager release
  home.stateVersion = "25.11";
}
