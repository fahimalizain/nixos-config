{ config, pkgs, pkgs-unstable, ... }:

{
  # User account settings (host-specific)
  home.username = "fahimalizain";
  home.homeDirectory = "/home/fahimalizain";

  # Host-specific packages for thinkpad-nixos
  # Common packages go in ../../home.nix
  home.packages = with pkgs; [
    kdePackages.kate
    python312
    uv
  ] ++ [
    pkgs-unstable.go  # Go from unstable channel (newer version)
    pkgs-unstable.agent-browser  # Headless browser automation CLI
  ];

  # Host-specific environment variables
  home.sessionVariables = {
    SSH_AUTH_SOCK = "/home/fahimalizain/.1password/agent.sock";
    NIXOS_CONFIG = "/home/fahimalizain/nixos-config";
  };
}
