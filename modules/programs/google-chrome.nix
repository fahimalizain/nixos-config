{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.programs.google-chrome;
in
{
  options.programs.google-chrome = {
    enable = mkEnableOption "Google Chrome browser";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.google-chrome ];
  };
}
