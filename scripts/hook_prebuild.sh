#!/usr/bin/env bash
# Pre-build hook - runs before nixos-rebuild
# Add all validation steps here

set -e

# Auto-detect repo root from script location
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Change to repo root so all git operations work
cd "$REPO_ROOT"

# Validate git worktree (nix flakes can only see tracked files)
"$SCRIPT_DIR/validate_git_worktree_ready.sh"

# Add more pre-build validations here as needed

echo "Pre-build checks passed."
