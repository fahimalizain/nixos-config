{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/programs/rustdesk.nix
    ../../modules/programs/1password.nix
    ../../modules/programs/google-chrome.nix
    ../../modules/programs/vscode.nix
    ../../modules/programs/opencode.nix
    ../../modules/services/tailscale.nix
    ../../modules/services/cloudflare.nix
    ./autostart.nix
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
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJMTFvMRPOzg6Y8LAdsAY2v8V5aVk6rYon6TzYJM9h2S op/ThinkpadNixOS"
    ];
  };

  # System packages
  environment.systemPackages = with pkgs; [
    git
    spotify
    slack
    nodejs_22
    jq
  ];

  # Enable program modules
  my_programs.rustdesk.enable = true;
  my_programs._1password = {
    enable = true;
    username = "fahimalizain";
  };
  my_programs.google-chrome.enable = true;
  my_programs.vscode.enable = true;
  my_programs.opencode = {
    enable = true;        # CLI version
    desktop.enable = true; # Desktop GUI version
    fixDbSymlink.enable = true;  # Fix database migration issue for nix flakes build
  };
  programs.firefox.enable = true;

  # nix-ld: Helps run dynamically linked binaries (not built for NixOS)
  # by providing common shared libraries in standard locations (/lib, /lib64)
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      zlib               # Compression library (used by many Python packages)
      stdenv.cc.cc.lib   # C++ standard library (libstdc++.so.6, needed by compiled Python wheels)
    ];
  };

  # Host-specific autostart applications
  my_services.autostart._1password = true;
  my_services.autostart.rustdesk = true;

  # Enable service modules
  my_services.tailscale = {
    enable = true;
    trayscale.enable = true;
  };
  my_services.cloudflare = {
    warp.enable = true;                      # Cloudflare One Client (WARP)
    tunnel.enable = true;                    # Cloudflare Tunnel (cloudflared)
    zerotrust.fahimalizain.enable = true;    # Zero Trust hosts (fahimalizain org)
  };

  # SSH server
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
    openFirewall = true;
  };

  # X11 and Desktop Environment
  services.xserver.enable = true;
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.settings = {
    Users.RememberLastSession = false;
  };
  services.displayManager.autoLogin = {
    enable = true;
    user = "fahimalizain";
  };
  services.displayManager.defaultSession = "plasmax11";
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

  # Never auto-sleep (laptop used as desktop)
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  # TrackPoint support (Lenovo ThinkPad)
  hardware.trackpoint.enable = true;
  hardware.trackpoint.emulateWheel = true;

  # TouchPad configuration with multi-finger gesture support
  services.libinput = {
    enable = true;
    touchpad = {
      tapping = true;
      tappingDragLock = true;
      naturalScrolling = true;
      disableWhileTyping = true;
      middleEmulation = true;
      # Enable multi-finger gestures
      clickMethod = "clickfinger";
    };
  };

  # Docker
  virtualisation.docker.enable = true;

  # Fingerprint sensor (Synaptics Prometheus MIS)
  services.fprintd.enable = false;

  # Allow passwordless nrb (nixos-rebuild build only, not switch)
  security.sudo.extraRules = [
    {
      users = [ "fahimalizain" ];
      commands = [
        {
          command = "${pkgs.nixos-rebuild}/bin/nixos-rebuild build";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # This value determines the NixOS release
  system.stateVersion = "25.11";
}
