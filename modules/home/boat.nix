{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.my_programs.boat;

  # The binary is vendor-managed, not Nix-managed: boat self-updates in place
  # (`boat self-update`, plus an automatic check at most every 6 hours after a
  # command), writing to ~/.ascii/bin/boat. A store path is read-only, so
  # packaging it would break the vendor's update path. This module only
  # declares what the curl installer could not write: PATH, the shell wrapper,
  # the config seed, and a loud warning when the binary is absent.
  binDir = "${config.home.homeDirectory}/.ascii/bin";
  bin = "${binDir}/boat";

  # Seeded once when missing; never overwritten, because `boat login` and
  # `boat onboard` may rewrite it.
  configJson = pkgs.writeText "boat-config.json" (builtins.toJSON {
    api_url = "https://boat.dev";
    channel = cfg.channel;
  });

  # Mirrors the wrapper the vendor installer appends to ~/.zshrc. The binary
  # writes the sandbox id to BOAT_CURRENT_ID_FILE so that `current` resolves to
  # the sandbox this shell last created or forked.
  boatFunction = ''
    boat() {
      if [ ! -x "${bin}" ]; then
        echo "boat: ${bin} is missing — see ~/nixos-config/docs/programs/boat.md" >&2
        return 127
      fi

      local _boat_id_file _boat_convo_file _boat_rc
      _boat_id_file="$(mktemp "''${TMPDIR:-/tmp}/boat-id.XXXXXX")" || return 1
      _boat_convo_file="$(mktemp "''${TMPDIR:-/tmp}/boat-convo.XXXXXX")" || {
        rm -f "$_boat_id_file"
        return 1
      }

      # Inline assignment scopes the vars to this one call, so a value the
      # parent shell already exported survives without save/restore.
      BOAT_CURRENT_ID_FILE="$_boat_id_file" \
      BOAT_CURRENT_CONVO_FILE="$_boat_convo_file" \
        "${bin}" "$@"
      _boat_rc=$?

      if [ "$_boat_rc" -eq 0 ]; then
        case "''${1:-}" in
          new|start|fork)
            [ -s "$_boat_id_file" ] && export BOAT_CURRENT_ID="$(tr -d '[:space:]' < "$_boat_id_file")"
            ;;
          prompt)
            [ -s "$_boat_convo_file" ] && export BOAT_CURRENT_CONVO="$(cat "$_boat_convo_file")"
            ;;
        esac
      fi

      rm -f "$_boat_id_file" "$_boat_convo_file"
      return "$_boat_rc"
    }
  '';
in
{
  options.my_programs.boat = {
    enable = mkEnableOption "boat.dev sandbox CLI (vendor-installed binary in ~/.ascii/bin)";

    channel = mkOption {
      type = types.str;
      default = "prod";
      description = "Release channel written to ~/.config/ascii/boat/config.json if that file does not exist yet.";
    };

    shellFunction = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Define the boat() wrapper so that `current` resolves to the sandbox the
        shell last created or forked. Interactive zsh/bash only: BOAT_CURRENT_ID
        cannot outlive a one-shot `zsh -c`, so scripts must pass explicit ids.
      '';
    };
  };

  config = mkIf cfg.enable {
    # hm-session-vars.sh — reaches bash login shells on the NixOS hosts.
    home.sessionPath = [ binDir ];

    # .zshenv is unguarded, so every zsh sees it, including the `zsh -c`
    # shells that coding agents and CI spawn. hm-session-vars.sh is skipped in
    # child shells once __HM_SESS_VARS_SOURCED is set, so PATH cannot come
    # from home.sessionPath alone.
    programs.zsh.envExtra = ''
      # boat.dev CLI (my_programs.boat)
      case ":$PATH:" in
        *":${binDir}:"*) ;;
        *) export PATH="${binDir}:$PATH" ;;
      esac
    '';

    # ~/.zshrc — interactive shells, same placement as the vendor installer.
    programs.zsh.initContent = mkIf cfg.shellFunction boatFunction;

    # ~/.bashrc — the NixOS hosts' interactive shell.
    programs.bash.initExtra = mkIf cfg.shellFunction boatFunction;

    # Offline, non-interactive, idempotent. Never runs the vendor installer
    # (it edits rc files and opens a browser). Absolute coreutils path because
    # an earlier activation entry already leaked /opt/homebrew/bin into PATH.
    home.activation.boat = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      _boat_config="${config.xdg.configHome}/ascii/boat/config.json"
      if [ ! -e "$_boat_config" ]; then
        run ${pkgs.coreutils}/bin/install -D -m 0644 ${configJson} "$_boat_config"
      fi

      if [ ! -x "${bin}" ]; then
        echo "" >&2
        echo "*** my_programs.boat: ${bin} is missing" >&2
        echo "***   curl -fsSL https://boat.dev/install | sh" >&2
        echo "***   rc-file 'Permission denied' errors are expected; the binary still installs" >&2
        echo "***   then: boat onboard   (browser sign-in, card required)" >&2
        echo "" >&2
      fi
    '';
  };
}
