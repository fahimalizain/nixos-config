{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.programs.opencode;
in
{
  options.programs.opencode = {
    enable = mkEnableOption "OpenCode AI coding assistant";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.opencode ];
  };
}
