# Secrets Management with sops-nix + 1Password

This repository uses [sops-nix](https://github.com/Mic92/sops-nix) for managing secrets, with age keys stored in 1Password.

## Workflow Overview

```
┌─────────────────┐     ┌──────────────┐     ┌────────────────┐
│   1Password     │────▶│   nrs/nrb    │────▶│  NixOS System  │
│  (Age private   │     │  (rebuild    │     │  (secrets      │
│   key stored)   │     │   script)    │     │   deployed)    │
└─────────────────┘     └──────────────┘     └────────────────┘
         │                                           ▲
         │         ┌────────────────┐                  │
         └────────▶│  .sops.yaml    │──────────────────┘
                   │ (Age public    │
                   │  key stored)   │
                   └────────────────┘
```

## Setup Steps

### 1. Generate Age Key

```bash
# Generate a new age key
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
```

### 2. Store Private Key in 1Password

1. Open 1Password
2. Create a **Secure Note** in your Private vault
3. Title: `NixOS Age Key`
4. Copy the **entire contents** of `~/.config/sops/age/keys.txt` into the note
5. **Delete the local file**: `rm ~/.config/sops/age/keys.txt`

### 3. Update .sops.yaml

Get your public key:
```bash
# If you still have the file
age-keygen -y ~/.config/sops/age/keys.txt

# Or from the 1Password note (look for line starting with # public key)
```

Edit `.sops.yaml` and replace `YOUR_AGE_PUBLIC_KEY_PLACEHOLDER` with your actual public key (starts with `age1...`).

### 4. Add Secrets

Edit `secrets/secrets.yaml` and add your secrets (e.g., RustDesk config).

### 5. Encrypt the Secrets File

```bash
# Make sure sops is available
nix-shell -p sops

# Encrypt the file
sops -e -i secrets/secrets.yaml

# Verify it's encrypted
head secrets/secrets.yaml  # Should show "ENC[AES256_GCM..."
```

## Usage

### Rebuild with Secrets (Automatic)

```bash
nrs   # Switch (rebuild and activate)
nrb   # Build only (test for errors)
```

These aliases:
1. Check if 1Password CLI is signed in
2. Extract the age key to `/tmp/nixos-sops-age-key`
3. Run the rebuild with the key
4. Clean up the key file

### Sign in to 1Password CLI

If you get "not signed in" errors:

```bash
op signin
```

Or use biometric unlock:
```bash
eval $(op signin)
```

### Edit Secrets

```bash
# Decrypt and open in editor
sops secrets/secrets.yaml

# Save and exit - sops will automatically re-encrypt
```

## Security Notes

- **Private key never committed**: Only the age public key is in `.sops.yaml`
- **Temporary key file**: The private key is extracted to `/tmp` only during rebuild
- **Automatic cleanup**: The rebuild script removes the key file after completion
- **Git-tracked encryption**: The encrypted `secrets.yaml` is safe to commit

## Troubleshooting

### "Failed to extract age key from 1Password"

- Make sure 1Password CLI is installed: `which op`
- Ensure you're signed in: `op signin`
- Check the vault/item path in the script matches your 1Password setup

### "sops decryption failed"

- Verify `.sops.yaml` has the correct public key
- Check that `secrets/secrets.yaml` is properly encrypted
- Run `sops secrets/secrets.yaml` to validate and re-encrypt

### "permission denied" on /tmp/nixos-sops-age-key

The rebuild script should set correct permissions (0600), but if needed:
```bash
chmod 600 /tmp/nixos-sops-age-key
```
