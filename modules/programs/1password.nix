{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.my_programs._1password;
in
{
  options.my_programs._1password = {
    enable = mkEnableOption "1Password CLI and GUI with personal polkit settings";
    username = mkOption {
      type = types.str;
      description = "User allowed to use 1Password GUI authentication";
    };
  };

  config = mkIf cfg.enable {
    programs._1password.enable = true;
    programs._1password-gui = {
      enable = true;
      polkitPolicyOwners = [ cfg.username ];
    };
  };
}
