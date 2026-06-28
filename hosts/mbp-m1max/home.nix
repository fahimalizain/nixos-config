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

  home.activation.install-openchamber = ''
    export PATH="/opt/homebrew/opt/node@24/bin:$PATH"
    $DRY_RUN_CMD npm install -g @openchamber/web
  '';

  home.shellAliases = {
    aerospace-ghost = "aerospace list-windows --all --json | jq -r '.[] | select(.\"window-title\"==\"\") | .\"window-id\"' | xargs -n1 aerospace close --window-id";
  };

  programs.zsh.initContent = ''
    eval "$(/opt/homebrew/bin/brew shellenv zsh)"
  '';
}
