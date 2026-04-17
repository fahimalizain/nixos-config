{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.my_programs.opencode;
in
{
  options.my_programs.opencode = {
    enable = mkEnableOption "OpenCode AI coding assistant";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.opencode ];
  };
}
