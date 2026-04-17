#!/usr/bin/env bash
# Rebuild script that extracts age key from 1Password

set -e

# Temporary key file
AGE_KEY_FILE="/tmp/nixos-sops-age-key"

# Clean up on exit
cleanup() {
    if [ -f "$AGE_KEY_FILE" ]; then
        rm -f "$AGE_KEY_FILE"
        echo "Cleaned up age key"
    fi
}
trap cleanup EXIT

# Check if 1Password CLI is signed in
if ! op account list > /dev/null 2>&1; then
    echo "1Password CLI not signed in. Please run: op signin"
    exit 1
fi

# Extract age key from 1Password
# Store your key as a Secure Note with title "NixOS Age Key"
# or adjust the vault/item path below
echo "Extracting age key from 1Password..."
if ! op read "op://Private/NixOS Age Key/notesPlain" > "$AGE_KEY_FILE" 2>/dev/null; then
    echo "Failed to extract age key from 1Password"
    echo "Make sure you have:"
    echo "  - A secure note titled 'NixOS Age Key' in your Private vault"
    echo "  - The age private key in the notes field"
    exit 1
fi

chmod 600 "$AGE_KEY_FILE"
echo "Age key extracted successfully"

# Determine rebuild command
if [ "$1" = "switch" ] || [ "$1" = "" ]; then
    CMD="switch"
else
    CMD="$1"
fi

# Run rebuild with age key
echo "Running: nixos-rebuild $CMD --flake .#thinkpad-nixos"
SOPS_AGE_KEY_FILE="$AGE_KEY_FILE" sudo -E nixos-rebuild "$CMD" --flake .#thinkpad-nixos
