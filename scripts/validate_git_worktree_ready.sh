#!/usr/bin/env bash
# Validates that the git worktree is ready for Nix flakes
# Nix flakes can only see files that are tracked by git

set -e

# Use NIXOS_CONFIG if set, otherwise auto-detect from script location
if [ -n "$NIXOS_CONFIG" ]; then
    REPO_ROOT="$NIXOS_CONFIG"
else
    SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
    REPO_ROOT="$(dirname "$SCRIPT_DIR")"
fi

cd "$REPO_ROOT"

# Check for untracked files
untracked_files=$(git ls-files --others --exclude-standard)

if [ -n "$untracked_files" ]; then
    echo "ERROR: Untracked files found in the repository:"
    echo "$untracked_files" | sed 's/^/  - /'
    echo ""
    echo "Nix flakes can only see files tracked by git."
    echo "Please stage or commit these files before building:"
    echo "  git add <files>"
    echo "  git commit -m 'your message'"
    exit 1
fi

# Check for staged but not committed files (warning only)
staged_files=$(git diff --cached --name-only)

if [ -n "$staged_files" ]; then
    echo "WARNING: Staged but uncommitted changes found:"
    echo "$staged_files" | sed 's/^/  - /'
    echo ""
    echo "These files will be included in the build, but consider committing them."
    echo ""
fi

echo "Git worktree is ready for Nix build."
exit 0
