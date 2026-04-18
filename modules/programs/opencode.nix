{ config, pkgs, lib, inputs, ... }:

with lib;

let
  cfg = config.my_programs.opencode;
  # Use nixpkgs-unstable for opencode packages
  # This keeps system packages at stable version, opencode uses unstable
  opencodePkgs = import inputs.nixpkgs-unstable {
    system = pkgs.system;
    config.allowUnfree = true;
  };
in
{
  options.my_programs.opencode = {
    enable = mkEnableOption "OpenCode AI coding assistant (CLI)";

    desktop = {
      enable = mkEnableOption "OpenCode AI coding assistant (Desktop GUI)";
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      environment.systemPackages = [ opencodePkgs.opencode ];
    })
    (mkIf cfg.desktop.enable {
      environment.systemPackages = [ opencodePkgs.opencode-desktop ];
    })
  ];
}
