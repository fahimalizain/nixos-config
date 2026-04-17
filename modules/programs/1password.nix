{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.programs._1password;
  cfgGui = config.programs._1password-gui;
in
{
  options.programs._1password = {
    enable = mkEnableOption "1Password CLI";
  };

  options.programs._1password-gui = {
    enable = mkEnableOption "1Password GUI";
  };

  config = mkMerge [
    (mkIf cfg.enable {
      programs._1password.enable = true;
    })
    (mkIf cfgGui.enable {
      programs._1password-gui = {
        enable = true;
        polkitPolicyOwners = [ "fahimalizain" ];
      };
    })
  ];
}
