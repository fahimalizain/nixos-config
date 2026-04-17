{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.my_programs.rustdesk;
in
{
  options.my_programs.rustdesk = {
    enable = mkEnableOption "RustDesk remote desktop";

    enableService = mkEnableOption "RustDesk background service for unattended remote access";

    secretsPath = mkOption {
      type = types.str;
      default = "rustdesk";
      description = "Path prefix in sops secrets for RustDesk config files";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.rustdesk-flutter ];

    # Deploy RustDesk config from sops secrets to both user and root directories
    sops.secrets = mkIf cfg.enableService {
      "${cfg.secretsPath}/RustDesk.toml" = {
        path = "/root/.config/rustdesk/RustDesk.toml";
        mode = "0600";
        owner = "root";
        group = "root";
      };
      "${cfg.secretsPath}/RustDesk2.toml" = {
        path = "/root/.config/rustdesk/RustDesk2.toml";
        mode = "0600";
        owner = "root";
        group = "root";
      };
    };

    # Ensure config directory exists before service starts
    systemd.tmpfiles.rules = mkIf cfg.enableService [
      "d /root/.config/rustdesk 0700 root root -"
    ];

    systemd.services.rustdesk = mkIf cfg.enableService {
      description = "RustDesk remote desktop service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "sops-nix.service" ];
      wants = [ "network.target" "sops-nix.service" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.rustdesk-flutter}/bin/rustdesk --service";
        Restart = "always";
        RestartSec = 3;
      };
    };
  };
}
