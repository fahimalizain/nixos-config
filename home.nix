{ config, pkgs, hostname, ... }:

{
  # Common packages for all hosts
  home.packages = with pkgs; [
    # Add shared packages here
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
      # npm global packages (NixOS-compatible)
      export NPM_CONFIG_PREFIX="$HOME/.npm-global"
      export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"
    '';
    shellAliases = {
      nrs = "$NIXOS_CONFIG/scripts/hook_prebuild.sh && sudo nixos-rebuild switch --flake $NIXOS_CONFIG#${hostname}";
      nrb = "$NIXOS_CONFIG/scripts/hook_prebuild.sh && sudo nixos-rebuild build --flake $NIXOS_CONFIG#${hostname}";
    };
  };

  # This value determines the Home Manager release
  home.stateVersion = "25.11";
}
