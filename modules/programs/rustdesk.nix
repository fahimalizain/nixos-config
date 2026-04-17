{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.my_programs.rustdesk;
in
{
  options.my_programs.rustdesk = {
    enable = mkEnableOption "RustDesk remote desktop";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.rustdesk-flutter ];
  };
}
