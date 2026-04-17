# OpenCode Module

This document explains how OpenCode is integrated into the NixOS configuration, the approaches considered, and why the current implementation was chosen.

## Overview

OpenCode (v1.4.7) is installed as a system package using its upstream flake, isolated from the stable nixpkgs to avoid dependency conflicts.

## The Problem

1. **Nixpkgs version is outdated**: NixOS 25.11 ships OpenCode v1.1.14, while upstream is at v1.4.7 (3 major versions behind)
2. **Build dependencies mismatch**: OpenCode v1.4.7 requires Bun ^1.3.11, but nixos-25.11 only has Bun 1.3.3
3. **System isolation needed**: We want stable Bun for the system, but cutting-edge Bun for building OpenCode

## Approaches Considered

### Approach 1: Direct Flake Input with Overlay

**Implementation**: Add opencode as a flake input and apply its overlay globally.

```nix
# flake.nix
inputs.opencode.url = "github:anomalyco/opencode/v1.4.7";

# In nixosSystem
nixpkgs.overlays = [ opencode.overlays.default ];
```

**Pros**:
- Simple, idiomatic NixOS pattern
- Works seamlessly with Home Manager
- Single package set (pkgs.opencode works everywhere)

**Cons**:
- Pollutes global nixpkgs with overlay
- All packages see the overlaid version
- `flake.nix` grows with each external dependency

**Verdict**: Rejected - we wanted isolation and minimal flake.nix changes.

### Approach 2: Sub-Flake Pattern

**Implementation**: Create a separate flake for external dependencies.

```nix
# external/flake.nix - holds all external deps
# Main flake.nix - just one input: external.url = "path:./external"
```

**Pros**:
- Keeps main flake.nix minimal
- Dependencies organized by concern
- Could have separate lock files per module

**Cons**:
- Two lock files to manage (main + external)
- Complex import chain
- Overkill for personal configs
- Breaks single source of truth for versions

**Verdict**: Rejected - too complex for a single-user system.

### Approach 3: Global Bun Override with Overlay

**Implementation**: Override Bun globally to use nixpkgs-unstable version.

```nix
nixpkgs.overlays = [
  (final: prev: {
    bun = nixpkgs-unstable.legacyPackages.${pkgs.system}.bun;
  })
  opencode.overlays.default
];
```

**Pros**:
- Fixes the build
- Simple implementation

**Cons**:
- Changes Bun version system-wide
- If you install `pkgs.bun` elsewhere, you get unstable version
- Violates principle of least surprise

**Verdict**: Rejected - too invasive, affects system packages.

### Approach 4: Isolated Nixpkgs Instance (Chosen)

**Implementation**: Create a separate nixpkgs instance just for OpenCode.

```nix
# modules/programs/opencode.nix
opencodePkgs = import inputs.nixpkgs-unstable {
  system = pkgs.system;
  overlays = [ inputs.opencode.overlays.default ];
};

package = opencodePkgs.opencode;
```

**Pros**:
- **Complete isolation**: OpenCode uses unstable dependencies, system stays on stable
- **Self-contained module**: All logic in one file
- **Minimal flake.nix**: Just declares inputs, no special logic
- **Reproducible**: Uses locked inputs via `specialArgs`
- **Extensible**: Pattern works for any future external packages

**Cons**:
- Slightly more memory usage (two nixpkgs evaluations)
- Module receives extra argument via `specialArgs`

**Verdict**: **Accepted** - best balance of isolation, simplicity, and maintainability.

## Final Implementation

### flake.nix

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    opencode = {
      url = "github:anomalyco/opencode/v1.4.7";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, opencode, ... }@inputs: {
    nixosConfigurations = {
      thinkpad-nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };  # Pass all inputs to modules
        modules = [
          ./hosts/thinkpad-nixos
          # ... other modules
        ];
      };
    };
  };
}
```

### modules/programs/opencode.nix

```nix
{ config, pkgs, lib, inputs, ... }:

with lib;

let
  cfg = config.my_programs.opencode;
  
  # Create isolated nixpkgs instance with unstable + opencode overlay
  # This keeps system packages on stable, while opencode builds with latest dependencies
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
```

## Key Insights

1. **Flakes require explicit inputs**: You cannot use external flakes without declaring them in `flake.nix`. This is by design for reproducibility.

2. **Overlays are global**: When you apply an overlay to nixpkgs, it affects ALL packages. Use isolated nixpkgs instances when you need different versions.

3. **nixpkgs-unstable vs nixos-25.11**:
   - `nixos-25.11` = Stable release, tested, quarterly updates
   - `nixpkgs-unstable` = Rolling release, daily updates, latest packages

4. **specialArgs vs _module.args**:
   - `specialArgs` in `nixosSystem`: Passes arguments to ALL modules
   - `_module.args`: Can be set per-module, but requires the module to be evaluated first

5. **Building from source**: The opencode flake builds from source (TypeScript/Bun project). This requires:
   - Correct Bun version
   - Node.js
   - All dependencies defined in the flake
   - No pre-built binary cache available (unless upstream provides one)

## Updating OpenCode

When a new version is released:

1. Edit `flake.nix` to update the version tag:
   ```nix
   opencode.url = "github:anomalyco/opencode/v1.5.0";
   ```

2. Update the flake.lock:
   ```bash
   nix flake update opencode
   ```

3. Test the build:
   ```bash
   nrb  # Build only
   nrs  # Build and activate
   ```

## Troubleshooting

### Build fails with Bun version mismatch

If you see:
```
error: This script requires bun@^1.X.X, but you are using bun@1.Y.Y
```

The isolated nixpkgs-unstable should provide a newer Bun. If not, update the unstable input:
```bash
nix flake update nixpkgs-unstable
```

### "undefined variable 'inputs'"

Make sure `specialArgs = { inherit inputs; }` is set in your `nixosSystem` configuration.

## References

- [OpenCode Repository](https://github.com/anomalyco/opencode)
- [OpenCode v1.4.7 Release](https://github.com/anomalyco/opencode/releases/tag/v1.4.7)
- [NixOS Overlays Documentation](https://nixos.wiki/wiki/Overlays)
- [Nix Flakes Wiki](https://nixos.wiki/wiki/Flakes)
