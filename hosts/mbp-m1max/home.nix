{ config, pkgs, hostname, ... }:

{
  home.username = "fahimalizain";
  home.homeDirectory = "/Users/fahimalizain";

  home.packages = [ ];

  home.activation.install-openchamber = ''
    export PATH="/opt/homebrew/opt/node@24/bin:$PATH"
    $DRY_RUN_CMD npm install -g @openchamber/web  # CLI/web tool (different from the openchamber brew cask in default.nix)
  '';

  home.shellAliases = {
    aerospace-ghost = "aerospace list-windows --all --json | jq -r '.[] | select(.\"window-title\"==\"\") | .\"window-id\"' | xargs -n1 aerospace close --window-id";
  };

  programs.zsh.initContent = ''
    eval "$(/opt/homebrew/bin/brew shellenv zsh)"
  '';
}
