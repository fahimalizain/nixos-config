{ config, pkgs, lib, inputs, ... }:

with lib;

let
  cfg = config.my_services.cloudflare;
  # Import nixos-unstable with allowUnfree for cloudflare-warp
  nixos-unstable = import inputs.nixos-unstable {
    system = pkgs.system;
    config.allowUnfree = true;
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

  config = mkMerge [
    (mkIf cfg.warp.enable {
      # Enable the cloudflare-warp service (module already in nixos-25.11)
      # but override the package to use nixos-unstable version
      services.cloudflare-warp = {
        enable = true;
        package = nixos-unstable.cloudflare-warp;
      };
    })
    (mkIf cfg.tunnel.enable {
      environment.systemPackages = [ nixos-unstable.cloudflared ];
    })
    (mkIf cfg.zerotrust.fahimalizain.enable {
      # Cloudflare Zero Trust virtual network hosts (fahimalizain organization)
      networking.hosts = {
        "100.96.0.1" = [ "CF-WorkPC" ];  # Work PC via Cloudflare WARP/Zero Trust
      };
    })
  ];
}
