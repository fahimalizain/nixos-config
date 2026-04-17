# Progress Log: sops-nix + 1Password Integration

## Date: 2026-04-17

## Objective
Set up sops-nix for secrets management with age keys stored in 1Password, and prepare to move RustDesk configuration into the repository.

## Changes Made

### 1. Added sops-nix to flake.nix
- Added `sops-nix` as a new flake input
- Imported `sops-nix.nixosModules.sops` in the NixOS configuration

### 2. Created .sops.yaml
- Configuration file for sops with age encryption
- Contains setup instructions for 1Password workflow
- Placeholder for age public key (to be filled by user)

### 3. Created secrets/ directory
- `secrets/secrets.yaml` - Template for encrypted secrets (unencrypted, ready for user to add secrets)
- `secrets/README.md` - Comprehensive documentation on:
  - Setup workflow with 1Password
  - How to encrypt/decrypt secrets
  - Troubleshooting guide

### 4. Created scripts/nixos-rebuild-with-secrets.sh
- Rebuild script that:
  - Checks 1Password CLI sign-in status
  - Extracts age key from 1Password (Secure Note titled "NixOS Age Key")
  - Runs nixos-rebuild with the key file
  - Automatically cleans up the temporary key file

### 5. Updated modules/programs/rustdesk.nix
- Added sops integration to deploy RustDesk config files
- Secrets are deployed to `/root/.config/rustdesk/` for the systemd service
- Added `systemd.tmpfiles.rules` to ensure directory exists
- Service now depends on `sops-nix.service`

### 6. Updated hosts/thinkpad-nixos/default.nix
- Added sops-nix configuration:
  - `sops.defaultSopsFile` pointing to secrets.yaml
  - `sops.age.keyFile` set to `/tmp/nixos-sops-age-key` (extracted by rebuild script)

### 7. Updated home.nix
- Modified `nrs` and `nrb` aliases to use the secrets script
- Added `nrs-legacy` and `nrb-legacy` aliases for rebuilds without secrets

### 8. Updated AGENTS.md
- Documented the new secrets management workflow
- Added rebuild commands with secrets
- Listed key files and their purposes

## Next Steps (User Action Required)

1. **Generate age key**:
   ```bash
   mkdir -p ~/.config/sops/age
   age-keygen -o ~/.config/sops/age/keys.txt
   ```

2. **Store in 1Password**:
   - Create Secure Note titled "NixOS Age Key" in Private vault
   - Copy contents of `~/.config/sops/age/keys.txt`
   - Delete local file: `rm ~/.config/sops/age/keys.txt`

3. **Update .sops.yaml**:
   - Get public key: `grep "public key" ~/.config/sops/age/keys.txt`
   - Replace `YOUR_AGE_PUBLIC_KEY_PLACEHOLDER` with actual `age1...` key

4. **Add RustDesk config to secrets/secrets.yaml**:
   - Copy content from `~/.config/rustdesk/RustDesk.toml`
   - Copy content from `~/.config/rustdesk/RustDesk2.toml`

5. **Encrypt secrets**:
   ```bash
   nix-shell -p sops
   sops -e -i secrets/secrets.yaml
   ```

6. **Test rebuild**:
   ```bash
   nrs  # Should extract key from 1Password and rebuild with secrets
   ```

## Files Modified/Created

### New Files:
- `.sops.yaml`
- `secrets/secrets.yaml`
- `secrets/README.md`
- `scripts/nixos-rebuild-with-secrets.sh`
- `PROGRESS.md` (this file)

### Modified Files:
- `flake.nix`
- `home.nix`
- `hosts/thinkpad-nixos/default.nix`
- `modules/programs/rustdesk.nix`
- `AGENTS.md`

## Notes
- The secrets.yaml is currently unencrypted (template only)
- User needs to add their actual secrets and encrypt before committing sensitive data
- The age private key is NEVER stored in the repository - only in 1Password
- The rebuild script uses 1Password CLI (`op`) which must be signed in before use
