{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.programs.rustdesk;
in
{
  options.programs.rustdesk = {
    enable = mkEnableOption "RustDesk remote desktop";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.rustdesk-flutter ];
  };
}
