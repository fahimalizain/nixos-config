{ config, pkgs, pkgs-unstable, hostname, ... }:

{
  home.username = "fahimalizain";
  home.homeDirectory = "/Users/fahimalizain";

  home.packages = with pkgs; [
    pkgs-unstable.agent-browser  # Headless browser automation CLI
  ];

  home.sessionVariables = {
    AGENT_BROWSER_SKILLS_DIR = "/etc/profiles/per-user/fahimalizain/share/agent-browser/skills";
  };

  programs.zsh.initContent = ''
    eval "$(/opt/homebrew/bin/brew shellenv zsh)"
  '';
}
