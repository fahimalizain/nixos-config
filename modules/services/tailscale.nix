{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.my_services.tailscale;
in
{
  options.my_services.tailscale = {
    enable = mkEnableOption "Tailscale VPN";
    trayscale.enable = mkEnableOption "Trayscale GUI for Tailscale" // { default = false; };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      services.tailscale = {
        enable = true;
        package = pkgs.tailscale;
      };
    })
    (mkIf (cfg.enable && cfg.trayscale.enable) {
      environment.systemPackages = [ pkgs.trayscale ];
    })
  ];
}
