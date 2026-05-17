# ThinkPad T14 Gen 2i — Clamshell Mode Investigation

> **Status: CONFIRMED WORKING**
>
> On 2026-05-17, a clean reboot was performed with **only** `button.lid_init_state=open` in `boot.kernelParams`.
> The system successfully initialized the eDP-1 panel while the lid was closed.
> RustDesk reported a display immediately after boot.
> `/proc/cmdline` confirmed no other kernel parameters were active.
>
> **Conclusion**: `button.lid_init_state=open` alone is sufficient. All other params (`video=eDP-1:e`, `i915.enable_psr=0`, `i915.disable_power_well=0`) and the X11 virtual display fallback were proven unnecessary for this machine.

## Problem Statement

When rebooting the laptop with the lid **closed** (clamshell/desktop mode), the system comes back up with **no active display outputs**. This causes RustDesk to report "No Displays" and the internal panel remains black even if the lid is opened after boot.

The issue only occurs on **fresh reboot**. If the system boots with the lid open and the lid is closed later, everything works fine.

## System Context

- **Model**: ThinkPad T14 Gen 2i (20W1S21K00)
- **GPU**: Intel Tiger Lake UY (i915, device ID 9a49)
- **Panel connector**: `card1-eDP-1`
- **Display stack**: X11 + SDDM + Plasma 6 (plasmax11)
- **Usage**: Always plugged into AC, used as a desktop replacement

## Investigation Timeline

### Initial Assumption: Sleep Policy

First guess was that `systemd-logind` was suspending on lid close. The system already had all sleep targets disabled:

```nix
systemd.targets.sleep.enable = false;
systemd.targets.suspend.enable = false;
systemd.targets.hibernate.enable = false;
systemd.targets.hybrid-sleep.enable = false;
```

Added `services.logind` settings to control lid behavior post-boot:

```nix
services.logind = {
  lidSwitch = "suspend";              # Close lid on battery → suspend
  lidSwitchExternalPower = "ignore";  # Close lid on AC → do nothing
  lidSwitchDocked = "ignore";         # Docked → do nothing
};
```

**Result**: Fixed post-boot lid-close behavior, but **did not fix the reboot-with-lid-closed issue**.

### Discovery: Kernel Log Reveals the Real Culprit

Booting with the lid closed and inspecting `journalctl -k` showed the smoking gun:

```
May 17 10:54:51 thinkpad-nixos kernel: i915 0000:00:02.0: [drm] Found TIGERLAKE/UY (device ID 9a49) display version 12.00 stepping C0
May 17 10:54:51 thinkpad-nixos kernel: [drm] forcing eDP-1 connector off
...
May 17 10:54:51 thinkpad-nixos kernel: i915 0000:00:02.0: [drm] Cannot find any crtc or sizes
```

The i915 driver **actively forces the eDP-1 connector off** when it detects a closed lid at boot time. The `video=eDP-1:d` kernel parameter (added earlier) was not enough because the driver checks the ACPI lid state **after** the force parameter and overrides it.

Confirmed by reading sysfs:

```bash
$ cat /sys/class/drm/card1-eDP-1/status
disconnected

$ cat /sys/class/drm/card1-eDP-1/enabled
disabled

$ cat /sys/class/drm/card1-eDP-1/dpms
Off

$ cat /proc/acpi/button/lid/LID/state
state:      closed

$ xrandr --listactivemonitors
Monitors: 0

$ xrandr | grep eDP-1
eDP-1 disconnected primary
```

The panel is physically present, the backlight sysfs exists, but the DRM layer reports it as disconnected because the lid was closed when the i915 driver initialized.

### Fix Attempt 1: Kernel Parameters (Partial)

Added several kernel params:

```nix
boot.kernelParams = [
  "video=eDP-1:d"              # Force DRM to treat eDP-1 as connected
  "i915.enable_psr=0"          # Disable Panel Self Refresh
  "button.lid_init_state=open" # Force ACPI lid state to "open" at boot
];
```

- `video=eDP-1:d` — Did not work. i915 overrides it with the lid-closed check.
- `i915.enable_psr=0` — Added speculatively. Present in both failing and (later) working boots, so it was not the deciding factor.
- `button.lid_init_state=open` — **Likely the critical fix**. Tells the kernel button driver to report the lid as open during early boot, which prevents i915 from triggering the "force connector off" path.

**Result after reboot**: Still no display. The `button.lid_init_state=open` parameter alone was not sufficient — i915 was still killing the panel.

### Fix Attempt 2: `:e` Instead of `:d`, Plus Power Well Lock

Changed `video=eDP-1:d` to `video=eDP-1:e` and added `i915.disable_power_well=0`:

```nix
boot.kernelParams = [
  "video=eDP-1:e"              # :e = enabled, stronger than :d = connected
  "i915.enable_psr=0"
  "i915.disable_power_well=0"  # Keep display power rails on at all times
  "button.lid_init_state=open"
];
```

- `:e` (enabled) vs `:d` (connected) — The DRM `video=` parameter documentation notes that `:e` forces the connector to remain in the enabled state, which keeps the display pipeline active.
- `i915.disable_power_well=0` — Prevents i915 from powering down the display power wells. On Tiger Lake, the eDP PHY may not re-initialize if the power well drops before X11 probes the connector.

**Result after reboot**: Still no display at first. The physical panel was still not coming up.

### Fix Attempt 3: Virtual Display Fallback (The Working Combination)

Added an X11 virtual head so that even if the physical panel stays dead, RustDesk has a display to capture:

```nix
services.xserver.extraConfig = ''
  Section "Device"
    Identifier "Device-modesetting[0]"
    Option "VirtualHeads" "1"
  EndSection
'';

services.xserver.displayManager.sessionCommands = ''
  ${pkgs.xorg.xrandr}/bin/xrandr --output VIRTUAL-1 --mode 1920x1080 --primary 2>/dev/null || true
  ${pkgs.xorg.xrandr}/bin/xrandr --output eDP-1 --auto 2>/dev/null || true
'';
```

Rebooted in clamshell mode with **all four changes combined**.

**Result**: ✅ **Working**. RustDesk shows a display after reboot.

## What Actually Fixed It?

Since all changes were applied at once for the working test, we cannot be 100% certain which subset is the minimal fix. However, based on the kernel log evidence, here is the most likely breakdown:

| Change | Likely Essential? | Reasoning |
|---|---|---|
| `button.lid_init_state=open` | **Very likely yes** | The kernel log `[drm] forcing eDP-1 connector off` is gated on the ACPI lid state. Without this, i915 always takes the "closed lid" code path during boot. |
| `video=eDP-1:e` | **Probably yes** | `:d` alone was proven insufficient. `:e` forces the connector to stay in the enabled state, keeping the CRTC pipeline alive even if the driver wants to turn it off. |
| `i915.disable_power_well=0` | **Maybe** | If `:e` already keeps the pipeline up, this may be redundant. But on Tiger Lake, the power well and the eDP PHY init sequence are tightly coupled. Safer to keep. |
| `i915.enable_psr=0` | **Probably no** | Was present in the failing boot too. Added for speculative panel-wake issues but not the root cause of the boot-time failure. |
| `VirtualHeads "1"` + `xrandr` | **Likely no** | If the physical panel now initializes, the virtual head is dead code. However, it acts as a valuable safety net if the physical display ever fails again. |
| `services.logind` | **Keep** | Unrelated to the boot issue. This is the actual "clamshell behavior" the user asked for (ignore lid close on AC). |

## Current Working Configuration (Pre-Prune)

```nix
{ config, pkgs, ... }:

{
  # --- Boot-time display fix ---
  boot.kernelParams = [
    "video=eDP-1:e"              # Force DRM to treat eDP-1 as enabled
    "i915.enable_psr=0"          # Disable Panel Self Refresh
    "i915.disable_power_well=0"  # Keep display power wells always on
    "button.lid_init_state=open" # Force ACPI lid state to "open" at boot
  ];

  # --- X11 virtual display fallback ---
  services.xserver.extraConfig = ''
    Section "Device"
      Identifier "Device-modesetting[0]"
      Option "VirtualHeads" "1"
    EndSection
  '';

  services.xserver.displayManager.sessionCommands = ''
    ${pkgs.xorg.xrandr}/bin/xrandr --output VIRTUAL-1 --mode 1920x1080 --primary 2>/dev/null || true
    ${pkgs.xorg.xrandr}/bin/xrandr --output eDP-1 --auto 2>/dev/null || true
  '';

  # --- Post-boot lid behavior ---
  services.logind = {
    lidSwitch = "suspend";
    lidSwitchExternalPower = "ignore";
    lidSwitchDocked = "ignore";
  };

  # (plus pre-existing sleep target disables)
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;
}
```

## Pruning Recommendations

### Option A — Conservative Minimal (Recommended)

Remove:
- `i915.enable_psr=0` (proven non-essential for the boot issue)
- `VirtualHeads` + `sessionCommands` (virtual display fallback, no longer needed if physical panel works)

Keep:
- `button.lid_init_state=open`
- `video=eDP-1:e`
- `i915.disable_power_well=0`
- `services.logind`

### Option B — Aggressive Minimal

Remove:
- `i915.enable_psr=0`
- `i915.disable_power_well=0`
- `VirtualHeads` + `sessionCommands`

Keep:
- `button.lid_init_state=open`
- `video=eDP-1:e`
- `services.logind`

### Option C — Nuclear Minimal (High Risk)

Remove everything except:
- `button.lid_init_state=open`
- `services.logind`

Not recommended without testing.

## Downsides of the Current Changes

- `video=eDP-1:e` + `disable_power_well=0` — The kernel will always keep the eDP panel powered. On battery with the lid open, you may see slightly higher power draw (sub-watt range). Negligible for a desk-bound machine.
- `button.lid_init_state=open` — The kernel reports the lid as open to drivers during boot. This only affects early boot initialization; once userspace takes over, the real lid state is read from ACPI again.
- `i915.enable_psr=0` — Disables Panel Self Refresh. On battery, could increase idle power draw by ~0.5–1 W. Again, negligible for AC-only use.

## References

- Linux DRM `video=` parameter documentation: `Documentation/admin-guide/kernel-parameters.rst`
- i915 driver lid handling: `drivers/gpu/drm/i915/display/intel_display.c` — `intel_connector_update_modes()` and lid-state checks
- `button.lid_init_state` kernel parameter: `drivers/acpi/button.c`
- X11 modesetting `VirtualHeads`: `man modesetting`
- ThinkPad T14 Gen 2i uses Synaptics Prometheus MIS fingerprint sensor, Intel AX201/AX211 WiFi+BT
