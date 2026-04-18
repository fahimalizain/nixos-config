# Host-specific autostart applications for thinkpad-nixos
#
# This module creates .desktop files in ~/.config/autostart/ that launch
# applications automatically when the user logs into the desktop session.
#
# Location of created files:
#   ~/.config/autostart/<app-name>.desktop
#
# Desktop environments (Plasma, GNOME, etc.) read this directory on login
# and execute any .desktop files found there.
#
# To add a new autostart application:
#   1. Add an option below: my_services.autostart.<app-name>
#   2. Add the xdg.configFile entry in the config section
#   3. Enable it in default.nix: my_services.autostart.<app-name> = true;
#
# See: https://specifications.freedesktop.org/autostart-spec/autostart-spec-latest.html

{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.my_services.autostart;
in
{
  options.my_services.autostart = {
    _1password = mkEnableOption "1Password GUI autostart on login";
  };

  config = mkIf cfg._1password {
    # Creates ~/.config/autostart/1password.desktop
    # Runs 1password --silent (starts minimized to system tray)
    home-manager.users.fahimalizain.xdg.configFile."autostart/1password.desktop".text = ''
      [Desktop Entry]
      Name=1Password
      Exec=1password --silent
      Icon=1password
      Type=Application
      Categories=Security;System;
      Comment=Password manager
      X-GNOME-Autostart-enabled=true
    '';
  };
}
