{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.my_programs.vscode;
in
{
  options.my_programs.vscode = {
    enable = mkEnableOption "Visual Studio Code";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.vscode ];
  };
}
