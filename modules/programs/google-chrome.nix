{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.my_programs.google-chrome;
in
{
  options.my_programs.google-chrome = {
    enable = mkEnableOption "Google Chrome browser";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.google-chrome ];
  };
}
