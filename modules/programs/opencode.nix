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

        # Relax bun version check - nixpkgs-unstable has bun 1.3.11, opencode wants 1.3.13
        # Patch the version check to accept bun >=1.3.11
        sed -i 's/semver.satisfies(process.versions.bun, expectedBunVersionRange)/true/' packages/script/src/index.ts
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
