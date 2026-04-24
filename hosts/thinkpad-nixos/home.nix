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
    poetry
  ] ++ [
    pkgs-unstable.go  # Go from unstable channel (newer version)
    pkgs-unstable.agent-browser  # Headless browser automation CLI
  ];

  # Host-specific environment variables
  home.sessionVariables = {
    SSH_AUTH_SOCK = "/home/fahimalizain/.1password/agent.sock";
    NIXOS_CONFIG = "/home/fahimalizain/nixos-config";
    AGENT_BROWSER_SKILLS_DIR = "/etc/profiles/per-user/fahimalizain/share/agent-browser/skills";

    # Expose libstdc++.so.6 to dynamically-linked binaries loaded via dlopen
    # (e.g. pip-installed Python wheels like pyzmq inside Poetry venvs).
    # nix-ld handles standalone executables, but dlopen'd .so libraries
    # still need LD_LIBRARY_PATH to find C++ runtime libraries on NixOS.
    LD_LIBRARY_PATH = "${pkgs.stdenv.cc.cc.lib}/lib";
  };
}
