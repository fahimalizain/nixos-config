{ config, pkgs, lib, inputs, operatingSystem ? "generic-linux", ... }:

with lib;

let
  cfg = config.my_services.cloudflare;
  # Import nixos-unstable with allowUnfree for cloudflare-warp
  nixos-unstable = import inputs.nixos-unstable {
    system = pkgs.system;
    config.allowUnfree = true;
  };
  zerotrustHosts = {
    "100.96.0.1" = [ "CF-WorkPC" ];  # Work PC via Cloudflare WARP/Zero Trust
    "100.96.0.17" = ["CF-ThinkPadNixOS"];
    "100.96.0.19" = ["CF-MBPM1Max"];
  };
in
{
  options.my_services.cloudflare = {
    warp = {
      enable = mkEnableOption "Cloudflare WARP (Cloudflare One Client)" // { default = false; };
    };
    tunnel = {
      enable = mkEnableOption "Cloudflare Tunnel (cloudflared)" // { default = false; };
    };
    zerotrust = {
      fahimalizain = {
        enable = mkEnableOption "Zero Trust hosts for fahimalizain organization" // { default = false; };
      };
    };
  };

  config = mkMerge ([] ++ optionals (operatingSystem == "nixos") [
    (mkIf cfg.warp.enable {
      # Enable the cloudflare-warp service (module already in nixos-25.11)
      # but override the package to use nixos-unstable version
      services.cloudflare-warp = {
        enable = true;
        package = nixos-unstable.cloudflare-warp;
      };
    })
  ] ++ [
    (mkIf cfg.tunnel.enable {
      environment.systemPackages = [ nixos-unstable.cloudflared ];
    })
    (mkIf cfg.zerotrust.fahimalizain.enable (
      # Cloudflare Zero Trust virtual network hosts (fahimalizain organization)
      if operatingSystem == "darwin" then {
        # nix-darwin doesn't have networking.hosts; append via activation script.
        # The activation script template only runs a hardcoded set of named scripts,
        # so we must use `extraActivation` (designed for user customization).
        # nix-darwin#939 added networking.hosts but was reverted (#1353) due to
        # /etc/hosts symlink breaking Docker Desktop and other tools.
        system.activationScripts.extraActivation.text = mkAfter ''
          echo "Adding Cloudflare Zero Trust hosts entries..." >&2
          ${concatStringsSep "\n" (mapAttrsToList (ip: names: ''
            grep -qxF '${ip} ${concatStringsSep " " names}' /etc/hosts 2>/dev/null || echo '${ip} ${concatStringsSep " " names}' >> /etc/hosts
          '') zerotrustHosts)}
        '';
      } else {
        networking.hosts = zerotrustHosts;
      }
    ))
  ]);
}
