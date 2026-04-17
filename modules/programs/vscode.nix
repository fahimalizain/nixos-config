{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.programs.vscode;
in
{
  options.programs.vscode = {
    enable = mkEnableOption "Visual Studio Code";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.vscode ];
  };
}
