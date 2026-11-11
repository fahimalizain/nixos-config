# boat Module

This document explains how the [boat.dev](https://boat.dev) sandbox CLI is wired
into this configuration, why the binary is deliberately **not** a Nix package,
and what still has to be done by hand on each new machine.

## Overview

boat gives you cloud Linux sandboxes (full Ubuntu VMs) driven by a single
`boat` binary. It is a **user-level** tool, so it lives in a home-manager
module, `modules/home/boat.nix`, imported once from `home.nix`:

```nix
# home.nix
imports = [ ./modules/home/boat.nix ];
```

Enable it per host:

```nix
# hosts/mbp-m1max/home.nix
my_programs.boat.enable = true;
```

This is a home-manager module, not a `modules/programs/` system module: every
thing it provides (`PATH`, a shell function, `~/.config`, `~/.ascii`) is
per-user. The `my_programs.*` prefix matches `my_programs.opencode`; the option
namespaces are separate, so there is no clash.

## Known Issues

### The vendor installer cannot run under home-manager

```console
$ curl -fsSL https://boat.dev/install | sh
sh: line 100: /Users/fahimalizain/.zshrc: Permission denied
```

`~/.zshrc` and `~/.zshenv` are home-manager symlinks into the read-only
`/nix/store`. The script's `strip_boat_block` does `cat "$_tmp" > "$1"` and dies
under `set -e`.

**The failure is partial, and that matters.** Line 54 runs before line 100, so
you still get:

| Step | Result |
| --- | --- |
| Download + SHA-256 verify | done |
| `~/.ascii/bin/boat` (7.5 MB) | **installed** |
| `~/.config/ascii/boat/config.json` | **written** |
| PATH block in `.zshrc` / `.zshenv` | skipped |
| `boat()` shell function | skipped |
| `~/.local/bin` + `/usr/local/bin` symlinks | skipped |
| `boat onboard` (sign-in + checkout) | skipped |

So a failed install still leaves a working binary — it just is not on `PATH`
and `current` does not resolve. This module supplies exactly the three skipped
pieces that are declarative.

Re-running the installer is safe if you ever want it (the blocks are delimited
by `# ASCII BOAT SHELL INTEGRATION START/END` sentinels and stripped before
re-adding), but it will keep failing at the same line for the same reason.

### `~/.local/bin` is not on `PATH` on macOS

The vendor's second symlink target is a no-op here: `~/.local/bin` is on
`PATH` for Debian/Ubuntu, not for this shell. Only `/usr/local/bin` matters on
macOS, and nothing else ships a `boat`, so the module does not create either
symlink. Add `/usr/local/bin` if a launchd/cron job ever needs the CLI.

## Implementation

### Why the binary is vendor-installed

`boat` **self-updates in place** — `boat self-update`, plus an automatic check
at most every 6 hours after a command ends, writing to `~/.ascii/bin/boat`.
A Nix-store copy is read-only, so packaging it would mean `BOAT_NO_UPDATE=1`
and a manual hash bump on every release. The download URL is
`/api/boat/cli/download?platform=darwin-arm64&channel=prod` — unversioned — so
a `fetchurl` hash would break on every vendor release anyway.

The split is therefore:

| Concern | Owner |
| --- | --- |
| The binary, its version, its updates | boat.dev (curl installer) |
| `PATH`, shell wrapper, config seed, warning | this module |

### Where each piece lands

| Mechanism | File | `zsh -c` sees it | bash login sees it |
| --- | --- | --- | --- |
| `programs.zsh.envExtra` | `~/.zshenv` | **yes** | no |
| `programs.zsh.initContent` | `~/.zshrc` | no | no |
| `programs.bash.initExtra` | `~/.bashrc` | no | interactive only |
| `home.sessionPath` | `hm-session-vars.sh` | only if not already sourced | via `.profile` |

`PATH` comes from `envExtra` because `.zshenv` has no guard: coding agents and
CI spawn `zsh -c`, and `hm-session-vars.sh` returns early in child shells once
`__HM_SESS_VARS_SOURCED` is inherited. `home.sessionPath` is set as well so
bash login shells on the NixOS hosts work.

The `boat()` wrapper is **interactive-only**, exactly like the vendor's:
`BOAT_CURRENT_ID` cannot outlive a one-shot `zsh -c`, so non-interactive
callers must pass explicit sandbox ids.

### The wrapper

The function points `BOAT_CURRENT_ID_FILE`/`BOAT_CURRENT_CONVO_FILE` at temp
files, runs the binary, and after a successful `new`/`start`/`fork`/`prompt`
lifts the written value into `BOAT_CURRENT_ID`/`BOAT_CURRENT_CONVO`:

```console
$ boat new                # bx_23456789
$ boat ssh current        # same sandbox, no id needed
```

Two deliberate differences from the vendor's version:

- The temp files are passed by **inline assignment** rather than `export`, so a
  value the parent shell already had survives without save/restore.
- Missing-binary handling is a `return 127` with a pointer to this doc instead
  of an obscure exec failure.

## First-time setup (per machine)

The module does not sign you in — that needs a browser and a card-required
checkout, so it stays manual:

```bash
curl -fsSL https://boat.dev/install | sh     # expect "Permission denied"; binary still installs
boat onboard                                  # browser sign-in, then plan checkout
```

`boat onboard` skips any step your account has already completed. Use the
**same sign-in method as before** (GitHub/Google/email/AgentID): a method that
was never connected opens a separate, empty account and asks you to subscribe
again.

Headless / CI instead of a browser:

```bash
echo "$BOAT_API_KEY" | boat login --key-stdin
```

## Troubleshooting

**`*** my_programs.boat: .../boat is missing` on every switch** — the binary is
gone (new machine, or you deleted `~/.ascii/bin`). Run the curl installer; the
rc-file errors are expected and harmless.

**`boat: command not found` in an agent shell** — the agent is not a zsh, or it
sanitised `PATH`. Check with `zsh -c 'command -v boat'`. For bash-only callers,
create `/usr/local/bin/boat` as a symlink.

**Version drift** — expected. `boat self-update` or wait for the 6-hour check.
Pin with `BOAT_NO_UPDATE=1` or `--no-update` for a benchmark/script.

**NixOS hosts** — if the Linux build is a glibc-dynamic ELF it will not run
without `programs.nix-ld.enable = true;` on the host (`autoPatchelfHook` if it
is ever packaged). Check with `file ~/.ascii/bin/boat`.

## Future Improvements

- Package the binary if boat.dev ever publishes versioned, hashable URLs.
- Add a `modules/services/`-style system module only if a daemon (not just the
  CLI) is ever needed.
- The `current`-tracking could be exposed to non-interactive shells via a
  `boat current` stdout contract, if the vendor adds one.
