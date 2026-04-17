{ config, pkgs, lib, inputs, ... }:

with lib;

let
  cfg = config.my_programs.opencode;
  # Create isolated nixpkgs with unstable + opencode overlay
  # This keeps system bun at stable version, opencode uses unstable
  opencodePkgs = import inputs.nixpkgs-unstable {
    system = pkgs.system;
    overlays = [ inputs.opencode.overlays.default ];
    config.allowUnfree = true;
  };
in
{
  options.my_programs.opencode = {
    enable = mkEnableOption "OpenCode AI coding assistant";
    package = mkOption {
      type = types.package;
      default = opencodePkgs.opencode;
      defaultText = literalExpression "opencode from isolated nixpkgs-unstable";
      description = "The OpenCode package to install. Built with nixpkgs-unstable dependencies, isolated from system packages.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
  };
}
