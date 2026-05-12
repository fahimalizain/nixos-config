{ config, pkgs, pkgs-unstable, ... }:

{
  systemd.user.services.whatsapp-personal = {
    Unit = {
      Description = "WhatsApp Personal Bot";
      After = [ "graphical-session.target" "network.target" ];
      Wants = [ "graphical-session.target" "network.target" ];
      StartLimitBurst = 0;
      StartLimitIntervalSec = 0;
    };

    Service = {
      Type = "simple";
      ExecStart = "${pkgs.nodejs_22}/bin/node /home/fahimalizain/projects/whatsapp-personal/src/server.js";
      WorkingDirectory = "/home/fahimalizain/projects/whatsapp-personal";
      RemainAfterExit = true;
      TimeoutStopSec = "5s";
      Environment = [
        "DISPLAY=:0"
        "PORT=55000"
        "FORWARD_TIMEOUT_MS=180000"
        "FORWARD_ALLOW_HTTP=true"
        "FORWARD_ALLOW_PRIVATE_IPS=true"
        "PUPPETEER_EXECUTABLE_PATH=${pkgs-unstable.google-chrome}/bin/google-chrome-stable"
      ];
      EnvironmentFile = "%h/.config/whatsapp-personal/env";
      Restart = "on-failure";
      RestartSec = "10s";
      RestartPreventExitStatus = "SIGTERM";
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
