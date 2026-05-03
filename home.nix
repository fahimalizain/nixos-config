{ config, pkgs, pkgs-unstable, hostname, lib, ... }:
let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
in
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
    ignores = [
      ".envrc"
    ];
  };

  # direnv (automatic shell env loading)
  programs.direnv = {
    enable = true;
    enableBashIntegration = !isDarwin;
    enableZshIntegration = isDarwin;
  };

  # npm global packages directory (NixOS requires non-nix-store location)
  home.file.".npm-global/.keep".text = "";

  # Shell configuration
  programs.bash.enable = !isDarwin;
  programs.zsh.enable = isDarwin;

  # Shell configuration (generic - applies to all enabled shells)
  home.sessionVariables = {
    NIXOS_CONFIG = "$HOME/nixos-config";
    NPM_CONFIG_PREFIX = "$HOME/.npm-global";
  };

  home.sessionPath = [ "$NPM_CONFIG_PREFIX/bin" ];

  home.shellAliases = let
    rebuild = if isDarwin then "darwin-rebuild" else "nixos-rebuild";
  in {
    nrs = "$NIXOS_CONFIG/scripts/hook_prebuild.sh && sudo ${rebuild} switch --flake $NIXOS_CONFIG#${hostname}";
    nrb = "$NIXOS_CONFIG/scripts/hook_prebuild.sh && sudo ${rebuild} build --flake $NIXOS_CONFIG#${hostname}";
  } // lib.optionalAttrs isDarwin {
    brew-upgrade = "brew update && brew upgrade";
  };

  # This value determines the Home Manager release
  home.stateVersion = "25.11";
}
