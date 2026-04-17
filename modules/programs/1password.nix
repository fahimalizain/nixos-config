{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.programs._1password_personal;
in
{
  options.programs._1password_personal = {
    enable = mkEnableOption "1Password CLI and GUI with personal polkit settings";
  };

  config = mkIf cfg.enable {
    programs._1password.enable = true;
    programs._1password-gui = {
      enable = true;
      polkitPolicyOwners = [ "fahimalizain" ];
    };
  };
}
