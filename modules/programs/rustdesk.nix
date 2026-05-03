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

    systemd.services.rustdesk = {
      description = "RustDesk remote desktop service";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.rustdesk-flutter}/bin/rustdesk --service";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
  };
}
