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
    userName = "fahimalizain";
    # userEmail = "your-email@example.com";  # Uncomment and set your email
  };

  # Bash configuration - migrated from .bashrc
  programs.bash = {
    enable = true;
    bashrcExtra = ''
      export SSH_AUTH_SOCK="/home/fahimalizain/.1password/agent.sock"
    '';
    shellAliases = {
      nrs = "sudo nixos-rebuild switch --flake .#thinkpad-nixos";
      nrb = "sudo nixos-rebuild build --flake .#thinkpad-nixos";
    };
  };

  # This value determines the Home Manager release
  home.stateVersion = "25.11";
}
