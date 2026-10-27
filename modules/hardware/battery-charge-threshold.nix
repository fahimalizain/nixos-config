{ config, lib, ... }:

with lib;

let
  cfg = config.my_hardware.batteryChargeThreshold;
in
{
  options.my_hardware.batteryChargeThreshold = {
    enable = mkEnableOption "battery charge threshold limits (ThinkPad)";

    start = mkOption {
      type = types.ints.between 0 100;
      default = 55;
      description = ''
        Battery level (%) at which charging resumes after the end threshold
        was reached.
      '';
    };

    end = mkOption {
      type = types.ints.between 0 100;
      default = 60;
      description = ''
        Battery level (%) at which charging stops. Keep this low (55-60%) for
        a machine that stays plugged in around the clock; use 80% if you also
        need longer runtime on battery.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.start < cfg.end;
        message = "my_hardware.batteryChargeThreshold.start must be lower than .end.";
      }
    ];

    # The ThinkPad embedded controller stores these thresholds in NVRAM, so
    # they survive reboots and suspend (Lenovo Vantage writes the same setting
    # on Windows). This unit re-applies them at every boot so the firmware
    # always matches this configuration.
    systemd.services.battery-charge-threshold = {
      description = "Set battery charge start/end thresholds";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        shopt -s nullglob
        for bat in /sys/class/power_supply/BAT*; do
          end_file="$bat/charge_control_end_threshold"
          start_file="$bat/charge_control_start_threshold"
          [ -w "$end_file" ] || continue
          [ -w "$start_file" ] || continue

          # The EC rejects a start value >= the current end value (and vice
          # versa), so write whichever limit is decreasing first.
          cur_start=$(< "$start_file")
          if (( ${toString cfg.start} < cur_start )); then
            echo ${toString cfg.start} > "$start_file"
            echo ${toString cfg.end} > "$end_file"
          else
            echo ${toString cfg.end} > "$end_file"
            echo ${toString cfg.start} > "$start_file"
          fi
        done
      '';
    };
  };
}
