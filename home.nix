{ config, pkgs, pkgs-unstable, hostname, lib, ... }:
let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
in
{
  # Common packages for all hosts
  home.packages = with pkgs; [
    procps       # watch, ps, top

    # Networking / LAN tools (cross-platform)
    arp-scan     # ARP-based LAN host discovery
    nmap         # network discovery and port scanning
    tcpdump      # packet analyzer
    mtr          # dynamic traceroute + ping combo
    dnsutils     # dig, nslookup
  ]
  # Linux-only networking tools
  ++ lib.optionals (!isDarwin) (with pkgs; [
    traceroute   # trace network paths
    ethtool      # NIC inspection and configuration
    iproute2     # ip, ss
  ]);

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
  # disable for darwin
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
    nrs = "$NIXOS_CONFIG/scripts/hook_prebuild.sh && sudo SSH_AUTH_SOCK=$SSH_AUTH_SOCK ${rebuild} switch --flake $NIXOS_CONFIG#${hostname}";
    nrb = "$NIXOS_CONFIG/scripts/hook_prebuild.sh && sudo SSH_AUTH_SOCK=$SSH_AUTH_SOCK ${rebuild} build --flake $NIXOS_CONFIG#${hostname}";
  } // lib.optionalAttrs isDarwin {
    brew-upgrade = "brew update && brew upgrade";
  };

  # This value determines the Home Manager release
  home.stateVersion = "25.11";
}
