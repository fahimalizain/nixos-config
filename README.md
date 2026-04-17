# NixOS Configuration

My personal NixOS configuration using Flakes and Home Manager.

## Structure

```
~/nixos-config/
├── flake.nix              # Entry point - defines inputs and outputs
├── home.nix               # Home Manager configuration (user-level)
├── README.md              # This file
├── AGENTS.md              # Instructions for AI assistants
├── hosts/
│   └── thinkpad-nixos/    # Host-specific configurations
│       ├── default.nix    # Main host configuration
│       └── hardware.nix   # Hardware-specific settings
```

## Quick Start

```bash
# Build and switch to this configuration
cd ~/nixos-config
sudo nixos-rebuild switch --flake .#thinkpad-nixos

# Update flake inputs
nix flake update

# Build without switching (test)
sudo nixos-rebuild build --flake .#thinkpad-nixos
```

## Adding Packages

**System-wide** (available to all users):
Edit `hosts/thinkpad-nixos/default.nix` and add to `environment.systemPackages`

**User-only** (just for fahimalizain):
Edit `home.nix` and add to `home.packages`

## Adding New Hosts

1. Copy `hosts/thinkpad-nixos/` to `hosts/new-hostname/`
2. Update `hardware.nix` for the new hardware
3. Add new host to `flake.nix` in the `nixosConfigurations` section
4. Build with `sudo nixos-rebuild switch --flake .#new-hostname`

## Home Manager

User configuration is managed via Home Manager as a NixOS module. This means:
- User packages and configs are applied automatically with `nixos-rebuild`
- No need to run `home-manager switch` separately
- Configs are in `home.nix`

## Useful Commands

```bash
# Search for packages
nix search nixpkgs firefox

# Enter a shell with a package
nix shell nixpkgs#nodejs

# See flake info
nix flake metadata

# Check what would change
nixos-rebuild dry-build --flake .#thinkpad-nixos
```

## Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [NixOS & Flakes Book](https://nixos-and-flakes.thiscute.world/)
- [nix-starter-configs](https://github.com/Misterio77/nix-starter-configs)
