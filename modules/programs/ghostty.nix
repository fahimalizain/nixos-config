{ config, pkgs, pkgs-unstable, lib, ... }:

with lib;

let
  cfg = config.my_programs.ghostty;
in
{
  options.my_programs.ghostty = {
    enable = mkEnableOption "Ghostty terminal emulator";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs-unstable.ghostty ];
  };
}
