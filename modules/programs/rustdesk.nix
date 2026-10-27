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
      documentation = [ "https://github.com/rustdesk/rustdesk/blob/master/res/rustdesk.service" ];

      # The service starts at boot and attaches to the active seat0 session once
      # the display manager is up, so it also covers the login screen.
      wants = [ "network-online.target" ];
      after = [ "network-online.target" "systemd-user-sessions.service" "display-manager.service" ];
      wantedBy = [ "multi-user.target" ];

      # rustdesk --service shells out to loginctl, ps, awk, grep and sudo to
      # detect the logged-in user and spawn `rustdesk --server` as that user.
      # NixOS units get a minimal PATH, so without this the per-user server is
      # never started and remote access only lives as long as the GUI window.
      path = [
        pkgs.rustdesk-flutter
        pkgs.procps
        pkgs.gawk
        pkgs.gnugrep
        pkgs.findutils
        pkgs.bash
        pkgs.coreutils
        "/run/wrappers"
        "/run/current-system/sw"
      ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.rustdesk-flutter}/bin/rustdesk --service";
        # Kill both `--tray` and `--server`, like upstream's unit does.
        ExecStop = "${pkgs.procps}/bin/pkill -f 'rustdesk --'";
        Restart = "always";
        RestartSec = "5s";
        User = "root";
        KillMode = "mixed";
        TimeoutStopSec = "30s";
        LimitNOFILE = "100000";
      };

      environment = {
        PULSE_LATENCY_MSEC = "60";
        PIPEWIRE_LATENCY = "1024/48000";
      };
    };
  };
}
