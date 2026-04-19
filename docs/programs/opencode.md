# OpenCode Module

This document explains how OpenCode is integrated into the NixOS configuration, the approaches considered, known upstream issues, and workarounds.

## Overview

OpenCode (CLI and Desktop) are installed from the upstream flake (v1.14.18), isolated from stable nixpkgs to avoid dependency conflicts.

**Current Status**: Build requires workarounds for upstream issues #23256, #11755, and #16885.

## Known Upstream Issues

### Issue #23256 - Missing prettier dependency (CLI build)

**Problem**: v1.14.18 introduced dynamic imports of `prettier` in `generate.ts`, but `prettier` is not declared in `package.json`. This breaks the Nix build:

```
error: Could not resolve: "prettier". Maybe you need to "bun install"?
```

**Workaround**: Patch `generate.ts` during `postPatch` to stub out the prettier imports.

### Issue #11755 - Missing cargo outputHashes (Desktop build)

**Problem**: The desktop package depends on git versions of `specta` and `tauri-specta`, but the flake doesn't provide the required `outputHashes` for `importCargoLock`.

**Error**:
```
error: No hash was found while vendoring the git dependency specta-2.0.0-rc.22.
```

**Workaround**: Override `cargoDeps` with the correct `outputHashes` for the git dependencies.

### Issue #16885 - Database migration on every run (Nix flakes builds)

**Problem**: When opencode is built locally via Nix flakes, it uses a different build path on each rebuild (e.g., `/nix/store/...-opencode-1.14.18`). This causes opencode to think it's a "new version" and triggers database migration on every run, which is slow and unnecessary.

**Symptom**:
```
# Every time you run opencode:
> opencode migrate db...
```

**Workaround**: Create a symlink from `opencode-stable.db` to `opencode.db`. The module provides a home-manager activation script that sets this up automatically.

**Enable the fix**:
```nix
my_programs.opencode = {
  enable = true;
  desktop.enable = true;
  fixDbSymlink.enable = true;  # Enable database symlink fix
};
```

## Implementation

### modules/programs/opencode.nix

```nix
{ config, pkgs, lib, inputs, ... }:

with lib;

let
  cfg = config.my_programs.opencode;

  # Custom overlay that patches opencode and opencode-desktop
  opencodePatchesOverlay = final: prev: {
    # Patch opencode to fix missing prettier dependency
    # https://github.com/anomalyco/opencode/issues/23256
    opencode = prev.opencode.overrideAttrs (old: {
      postPatch = (old.postPatch or "") + ''
        substituteInPlace packages/opencode/src/cli/cmd/generate.ts \
          --replace-fail 'const prettier = await import("prettier")' 'const prettier = { format: async (s: string) => s }' \
          --replace-fail 'const babel = await import("prettier/plugins/babel")' 'const babel = {}' \
          --replace-fail 'const estree = await import("prettier/plugins/estree")' 'const estree = {}'
      '';
    });

    # Rebuild opencode-desktop with patched opencode and fixed cargo hashes
    # https://github.com/anomalyco/opencode/issues/11755
    opencode-desktop = (final.callPackage (inputs.opencode + "/nix/desktop.nix") {
      opencode = final.opencode;  # Use the patched opencode from final
    }).overrideAttrs (old: {
      cargoDeps = final.rustPlatform.importCargoLock {
        lockFile = inputs.opencode + "/packages/desktop/src-tauri/Cargo.lock";
        outputHashes = {
          "specta-2.0.0-rc.22" = "sha256-YsyOAnXELLKzhNlJ35dHA6KGbs0wTAX/nlQoW8wWyJQ=";
          "tauri-2.9.5" = "sha256-dv5E/+A49ZBvnUQUkCGGJ21iHrVvrhHKNcpUctivJ8M=";
          "tauri-specta-2.0.0-rc.21" = "sha256-n2VJ+B1nVrh6zQoZyfMoctqP+Csh7eVHRXwUQuiQjaQ=";
        };
      };
    });
  };

  # Create isolated nixpkgs with unstable + upstream overlay + our patches
  # Our patches overlay must come AFTER the upstream one so we can override its packages
  opencodePkgs = import inputs.nixpkgs-unstable {
    system = pkgs.system;
    config.allowUnfree = true;
    overlays = [
      inputs.opencode.overlays.default  # First: add opencode and opencode-desktop
      opencodePatchesOverlay             # Second: patch them
    ];
  };
in
{
  options.my_programs.opencode = {
    enable = mkEnableOption "OpenCode AI coding assistant (CLI)";

    desktop = {
      enable = mkEnableOption "OpenCode AI coding assistant (Desktop GUI)";
    };

    fixDbSymlink = {
      enable = mkEnableOption "Fix database migration issue by symlinking opencode-stable.db to opencode.db (recommended for nix flakes builds)";
      username = mkOption {
        type = types.str;
        default = "fahimalizain";
        description = "Username for which to set up the database symlink";
      };
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      environment.systemPackages = [ opencodePkgs.opencode ];
    })
    (mkIf cfg.desktop.enable {
      environment.systemPackages = [ opencodePkgs.opencode-desktop ];
    })
    (mkIf cfg.fixDbSymlink.enable {
      # Fix for opencode database migration issue
      # See: https://github.com/anomalyco/opencode/issues/16885
      # Creates symlink from opencode-stable.db to opencode.db to prevent
      # database migration on every run for locally built opencode (nix flakes)
      home-manager.users.${cfg.fixDbSymlink.username}.home.activation.opencodeDbSymlink = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        opencodeDir="$HOME/.local/share/opencode"
        stableDb="$opencodeDir/opencode-stable.db"
        targetDb="$opencodeDir/opencode.db"

        if [ -d "$opencodeDir" ]; then
          # If stable db exists and target doesn't exist or is not already the correct symlink
          if [ -f "$stableDb" ]; then
            if [ ! -e "$targetDb" ]; then
              $DRY_RUN_CMD ln -s "$stableDb" "$targetDb"
            elif [ -L "$targetDb" ] && [ "$(readlink "$targetDb")" != "$stableDb" ]; then
              $DRY_RUN_CMD rm "$targetDb"
              $DRY_RUN_CMD ln -s "$stableDb" "$targetDb"
            fi
          fi
        fi
      '';
    })
  ];
}
```

## Key Design Decisions

### Why Two Overlays?

The implementation uses two overlays in sequence:

1. **Upstream overlay** (`inputs.opencode.overlays.default`): Adds `opencode` and `opencode-desktop` packages
2. **Patches overlay** (`opencodePatchesOverlay`): Overrides both packages to fix build issues

This ordering is critical - patches must come AFTER the upstream overlay so `prev.opencode` refers to the upstream package, and `final.opencode` refers to the patched version.

### Why Rebuild opencode-desktop?

`opencode-desktop` copies the `opencode` CLI as a sidecar binary during its build. If we just patched `opencode`, the desktop build would still use the unpatched version as its dependency. By using `final.callPackage` with `opencode = final.opencode`, we ensure the desktop is built with the patched CLI.

## Usage

Enable in your host configuration:

```nix
my_programs.opencode = {
  enable = true;        # CLI version (v1.14.18)
  desktop.enable = true; # Desktop GUI (v1.14.18)
  fixDbSymlink.enable = true;  # Fix database migration issue for nix flakes builds (recommended)
};
```

## Updating OpenCode

When a new version is released:

1. Check if upstream has fixed the issues:
   - [#23256](https://github.com/anomalyco/opencode/issues/23256) - prettier dependency
   - [#11755](https://github.com/anomalyco/opencode/issues/11755) - cargo outputHashes
   - [#16885](https://github.com/anomalyco/opencode/issues/16885) - database migration on every run (nix flakes)

2. Edit `flake.nix` to update the version tag:
   ```nix
   opencode.url = "github:anomalyco/opencode/v1.15.0";
   ```

3. Update the flake.lock:
   ```bash
   nix flake update opencode
   ```

4. Test the build:
   ```bash
   nrb  # Build only
   nrs  # Build and activate
   ```

## Troubleshooting

### substituteInPlace fails silently

If the build still fails with the same error, the substitution pattern may not match. Check the actual source file:

```bash
# Extract the source and check the file
nix build .#nixosConfigurations.thinkpad-nixos.config.system.build.toplevel --dry-run 2>&1 | grep opencode
cat /nix/store/...-source/packages/opencode/src/cli/cmd/generate.ts | head -40
```

The pattern must match exactly, including quotes and spacing.

### Hash mismatch in cargoDeps

If you see:
```
error: hash mismatch in fixed-output derivation '...-specta-...'
```

The `outputHashes` need updating. Run the build to get the correct hash from the error message and update it in the module.

### "undefined variable 'inputs'"

Make sure `specialArgs = { inherit inputs; }` is set in your `nixosSystem` configuration.

## Future Improvements

Once upstream fixes the issues:

1. **Remove the prettier patch**: When #23256 is fixed, remove the `postPatch` override for `opencode`
2. **Remove cargoDeps override**: When #11755 is fixed, remove the `cargoDeps` override for `opencode-desktop`
3. **Remove database symlink fix**: When #16885 is fixed upstream, remove the `fixDbSymlink` option and activation script
4. **Simplify to one overlay**: Just use `inputs.opencode.overlays.default` directly

## References

- [OpenCode Repository](https://github.com/anomalyco/opencode)
- [OpenCode v1.14.18 Release](https://github.com/anomalyco/opencode/releases/tag/v1.14.18)
- [Issue #23256 - prettier dependency](https://github.com/anomalyco/opencode/issues/23256)
- [Issue #11755 - cargo outputHashes](https://github.com/anomalyco/opencode/issues/11755)
- [Issue #16885 - database migration on every run](https://github.com/anomalyco/opencode/issues/16885)
- [NixOS Overlays Documentation](https://nixos.wiki/wiki/Overlays)
