# ThinkPad T14 Gen 2i (20W1S21K00)
#
# Snapshot of the NixOS 26.05 system currently running on this machine.
# Everything mirrors the stock installer configuration except:
#   - hostname is thinkpad-nixos (matches the flake attribute / nrs alias)
#   - 1Password GUI + CLI are installed
#   - RustDesk is installed for remote desktop access
#   - battery charge is capped at 60% / resumes at 55% (24x7 host)
#   - flakes are enabled, which is required to rebuild from ~/nixos-config
#
# Keep this file in sync with the live system: anything configured by hand
# outside this repo will be lost on the next rebuild.

{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./autostart.nix
    ../../modules/hardware/battery-charge-threshold.nix
    ../../modules/programs/1password.nix
    ../../modules/programs/rustdesk.nix
    ../../modules/services/k3s.nix
    ../../modules/services/tailscale.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking.hostName = "thinkpad-nixos";
  networking.networkmanager.enable = true;

  # NetworkManager applet for the LXQt panel
  programs.nm-applet.enable = true;

  # Time zone
  time.timeZone = "Asia/Kolkata";

  # Locale
  i18n.defaultLocale = "en_IN";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_IN";
    LC_IDENTIFICATION = "en_IN";
    LC_MEASUREMENT = "en_IN";
    LC_MONETARY = "en_IN";
    LC_NAME = "en_IN";
    LC_NUMERIC = "en_IN";
    LC_PAPER = "en_IN";
    LC_TELEPHONE = "en_IN";
    LC_TIME = "en_IN";
  };

  # User account
  users.users.fahimalizain = {
    isNormalUser = true;
    description = "Fahim Ali Zain";
    extraGroups = [ "networkmanager" "wheel" ];
  };

  # X11 + LXQt desktop
  services.xserver.enable = true;
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.desktopManager.lxqt.enable = true;
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Printing
  services.printing.enable = true;

  # Audio with PipeWire
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Firefox
  programs.firefox.enable = true;

  # 1Password GUI + CLI. polkitPolicyOwners lets the GUI unlock without a
  # root authentication prompt.
  my_programs._1password = {
    enable = true;
    username = "fahimalizain";
  };

  # Start 1Password minimised to the system tray on login.
  # autostart.nix writes ~/.config/autostart/1password.desktop.
  my_services.autostart._1password = true;

  # RustDesk remote desktop. The module installs rustdesk-flutter and runs
  # the background service, so incoming connections work without a login.
  my_programs.rustdesk.enable = true;

  # Start the RustDesk GUI on login.
  # autostart.nix writes ~/.config/autostart/rustdesk.desktop.
  my_services.autostart.rustdesk = true;

  # Single-node k3s control plane. Flux CD manages workloads; cluster
  # manifests live in the separate homek3s repo.
  #
  # The MagicDNS name is a TLS SAN so kubectl from the MacBook can verify
  # the API certificate.
  my_services.k3s = {
    enable = true;
    tlsSANs = [ "thinkpad-nixos.tail8395b3.ts.net" ];
  };

  # Stable address for the API, independent of Wi-Fi/DHCP changes. The k3s
  # module opens 6443 on tailscale0 when this is enabled.
  my_services.tailscale.enable = true;

  # This machine runs 24x7 on AC power, so keep the battery in its
  # long-life window instead of holding it at 100% all the time.
  # The ThinkPad EC persists these values across reboots and suspend.
  my_hardware.batteryChargeThreshold = {
    enable = true;
    start = 55;
    end = 60;
  };

  # Allow unfree packages (1Password is unfree)
  nixpkgs.config.allowUnfree = true;

  # System packages
  environment.systemPackages = with pkgs; [
    vim
    wget
    vscode
    google-chrome
    nodejs
    btop
    # Not in the stock install, but the nrs/nrb aliases run a pre-build hook
    # that calls git, and flakes only see git-tracked files.
    git
  ];

  # nix-ld lets unpatched binaries run (VS Code extensions, pip wheels, ...)
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc
    zlib
  ];

  # Required to rebuild this system from the flake in ~/nixos-config.
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # First NixOS release installed on this machine — do not bump.
  system.stateVersion = "26.05";
}
