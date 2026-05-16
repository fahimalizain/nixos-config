{ config, pkgs, pkgs-unstable, ... }:

{
  # Timer that triggers the service daily at 7PM
  systemd.user.timers.faaz-solar = {
    Unit = {
      Description = "Faaz Solar - Daily Data Collection Timer";
    };

    Timer = {
      # Run daily at 7:00 PM (19:00)
      OnCalendar = "19:00";

      # Run immediately if we missed the last trigger (e.g., system was off)
      Persistent = true;

      # Accuracy for timer coalescing (slight delay allowed for power saving)
      AccuracySec = "1min";
    };

    Install = {
      WantedBy = [ "timers.target" ];
    };
  };

  # The service that actually runs when triggered by the timer
  systemd.user.services.faaz-solar = {
    Unit = {
      Description = "Faaz Solar - Solar Data Collection Service";
      After = [ "network.target" ];
    };

    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.nodejs_22}/bin/node /home/fahimalizain/projects/faaz-solar/index.js";
      WorkingDirectory = "/home/fahimalizain/projects/faaz-solar";

      Environment = [
        "NODE_ENV=production"
        "DISPLAY=:0"
        "PUPPETEER_EXECUTABLE_PATH=${pkgs-unstable.google-chrome}/bin/google-chrome-stable"
      ];

      # Environment file for secrets (create this file with actual credentials)
      EnvironmentFile = "%h/.config/faaz-solar/env";
    };
  };

  # Commands to manage the timer/service:
  #
  # Enable and start the timer (runs daily at 7PM):
  #   systemctl --user enable faaz-solar.timer
  #   systemctl --user start faaz-solar.timer
  #
  # Check timer status and next scheduled run:
  #   systemctl --user list-timers faaz-solar
  #
  # Check service logs:
  #   systemctl --user status faaz-solar
  #   journalctl --user -u faaz-solar -f
  #
  # Stop/disable:
  #   systemctl --user stop faaz-solar.timer
  #   systemctl --user disable faaz-solar.timer
  #
  # Trigger manually (for testing):
  #   systemctl --user start faaz-solar
}
