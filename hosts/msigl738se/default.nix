# MSI GL73 8SE (msigl738se)
#
# k3s agent (worker) joining the thinkpad-nixos control plane over Tailscale.
# Mirrors hosts/thinkpad-nixos except:
#   - hostname is msigl738se
#   - k3s runs as an agent, not a server
#   - no battery charge threshold (the ThinkPad module uses a Lenovo EC
#     interface this machine does not have)
#
# Keep this file in sync with the live system: anything configured by hand
# outside this repo will be lost on the next rebuild.

{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./autostart.nix
    ../../modules/programs/1password.nix
    ../../modules/programs/rustdesk.nix
    ../../modules/services/k3s.nix
    ../../modules/services/tailscale.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking.hostName = "msigl738se";
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

  # k3s worker joining the control plane on thinkpad-nixos. The join token
  # is a secret and is deliberately not in this public repo. Before the
  # first start, copy it from the server:
  #
  #   sudo install -d -m 700 /var/lib/rancher/k3s
  #   ssh -t fahimalizain@thinkpad-nixos.tail8395b3.ts.net \
  #     'sudo cat /var/lib/rancher/k3s/server/node-token' \
  #     | tr -d '\r' \
  #     | sudo install -m 600 /dev/stdin /var/lib/rancher/k3s/agent-token
  #
  # k3s restarts until the file exists. Tailscale must also be logged in
  # (`sudo tailscale up`) before the agent can reach the server.
  my_services.k3s = {
    enable = true;
    role = "agent";
    serverAddr = "https://thinkpad-nixos.tail8395b3.ts.net:6443";
    tokenFile = "/var/lib/rancher/k3s/agent-token";
    nodeLabels = [ "node-role.kubernetes.io/worker=" ];
  };

  # Stable address for the agent, independent of Wi-Fi/DHCP changes. The
  # k3s module opens kubelet and flannel ports on tailscale0 when this is
  # enabled.
  my_services.tailscale.enable = true;

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
    openssl
  ];

  # Required to rebuild this system from the flake in ~/nixos-config.
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # First NixOS release installed on this machine — do not bump.
  system.stateVersion = "26.05";
}
