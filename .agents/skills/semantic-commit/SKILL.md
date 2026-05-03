---
name: semantic-commit
description: |
  Creates semantic commit messages with hostname scoping for this NixOS config repository.
  Use this skill whenever the user asks you to commit changes or describes a commit task.
  The skill detects which NixOS host(s) were modified (from hosts/ directory) and includes
  the hostname in the commit message scope, e.g. `feat(thinkpad-nixos): add vscode`.
---

# Semantic Commit with Hostname Scoping

## Available Hosts

The repository has these hosts in `hosts/`:

- `thinkpad-nixos` — Current laptop
- `mbp-m1max` — Another machine

Detect the relevant hostname by checking which files under `hosts/` were modified in the diff.

## Commit Message Format

```
type(hostname): description in imperative mood

Optional body with details, context, or reasoning.
```

The hostname is the directory name under `hosts/` that the changes affect. If changes touch multiple hosts, use `type(multi): description` or list them in the body.

## Allowed Types

| Type       | When to Use                                                         |
|------------|---------------------------------------------------------------------|
| `feat`     | New feature, package, or module                                     |
| `fix`      | Bug fix or correction                                               |
| `chore`    | Maintenance, refactoring, cleanup, dependency updates                |
| `docs`     | Documentation changes only                                          |
| `refactor` | Code change that neither fixes a bug nor adds a feature              |
| `config`   | Configuration changes (settings, options, environment variables)     |

## Examples

- `feat(thinkpad-nixos): add vscode and google-chrome`
- `config(thinkpad-nixos): set locale to en_IN`
- `fix(mbp-m1max): correct timezone to Asia/Kolkata`
- `chore(multi): update flake.lock`
- `docs(multi): add modules directory philosophy`
- `refactor(thinkpad-nixos): extract docker config to module`

## How to Determine the Hostname

1. Run `git diff --cached --stat` or `git diff --stat` to see which files changed.
2. Look for paths starting with `hosts/<hostname>/`.
3. Use the matching hostname in the commit scope.
4. If no host-specific files changed (e.g. `flake.nix`, `home.nix`, `AGENTS.md`), use `multi` as the scope.

## Edge Cases

- **No host files changed**: Use `multi` scope.
- **Multiple hosts changed**: Use `multi` scope.
- **Only non-host files changed** (e.g. `modules/`, `home.nix`, `flake.nix`): Use `multi` scope.
- **Hostname with hyphens**: Keep it as-is (e.g. `thinkpad-nixos`, `mbp-m1max`).
- **New host being added**: Use the new hostname as the scope.
