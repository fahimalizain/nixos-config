{ config, pkgs, ... }:

{
  home.username = "fahimalizain";
  home.homeDirectory = "/home/fahimalizain";

  # Packages for user
  home.packages = with pkgs; [
    # Add your user packages here
    # e.g., firefox, vscode, etc.
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
  };

  # This value determines the Home Manager release
  home.stateVersion = "25.11";
}
