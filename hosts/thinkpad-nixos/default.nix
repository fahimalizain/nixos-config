{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/programs/rustdesk.nix
    ../../modules/programs/1password.nix
    ../../modules/programs/google-chrome.nix
    ../../modules/programs/vscode.nix
    ../../modules/programs/opencode.nix
  ];

  # Boot loader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking.hostName = "thinkpad-nixos";
  networking.networkmanager.enable = true;

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

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # User account
  users.users.fahimalizain = {
    isNormalUser = true;
    description = "Fahim Ali Zain";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
  };

  # System packages
  environment.systemPackages = with pkgs; [
    git
  ];

  # Enable program modules
  programs.rustdesk.enable = true;
  programs._1password_personal.enable = true;
  programs.google-chrome.enable = true;
  programs.vscode.enable = true;
  programs.opencode.enable = true;
  programs.firefox.enable = true;

  # X11 and Desktop Environment
  services.xserver.enable = true;
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Printing
  services.printing.enable = true;

  # Audio with Pipewire
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # TrackPoint support (Lenovo ThinkPad)
  hardware.trackpoint.enable = true;
  hardware.trackpoint.emulateWheel = true;

  # Docker
  virtualisation.docker.enable = true;

  # This value determines the NixOS release
  system.stateVersion = "25.11";
}
