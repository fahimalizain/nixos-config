{ config, pkgs, lib, inputs, ... }:

with lib;

let
  cfg = config.my_programs.opencode;

  # Custom overlay that patches opencode and opencode-desktop
  # Note: v1.17.x upstream opencode.nix already handles the bun version check
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

    # Build opencode-desktop with patched opencode + bun version fix
    # Upstream opencode.nix postPatch fixes bun check for CLI only;
    # desktop gets fresh unpatched src, so we need to patch here too.
    opencode-desktop = (final.callPackage (inputs.opencode + "/nix/desktop.nix") {
      opencode = final.opencode;
    }).overrideAttrs (old: {
      postPatch = (old.postPatch or "") + ''
        # Relax bun version check for desktop build
        sed -i 's/throw new Error(`This script requires bun@/console.warn(`Warning: This script requires bun@/' packages/script/src/index.ts
      '';
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
      enable = mkEnableOption "Fix database migration issue by symlinking opencode.db to opencode-local.db (recommended for nix flakes builds)";
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
      # Creates symlink from opencode.db to opencode-local.db to prevent
      # database migration on every run for locally built opencode (nix flakes)
      home-manager.users.${cfg.fixDbSymlink.username}.home.activation.opencodeDbSymlink = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        opencodeDir="$HOME/.local/share/opencode"
        localDb="$opencodeDir/opencode-local.db"
        targetDb="$opencodeDir/opencode.db"

        if [ -d "$opencodeDir" ]; then
          # If local db exists and target doesn't exist or is not already the correct symlink
          if [ -f "$localDb" ]; then
            if [ ! -e "$targetDb" ]; then
              $DRY_RUN_CMD ln -s "$localDb" "$targetDb"
            elif [ -L "$targetDb" ] && [ "$(readlink "$targetDb")" != "$localDb" ]; then
              $DRY_RUN_CMD rm "$targetDb"
              $DRY_RUN_CMD ln -s "$localDb" "$targetDb"
            fi
          fi
        fi
      '';
    })
  ];
}
