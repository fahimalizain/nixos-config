# ThinkPad T14 Gen 2i - System Specifications

## Hardware Overview

| Component | Specification |
|-----------|-------------|
| **Model** | Lenovo ThinkPad T14 Gen 2i |
| **Machine Type** | 20W1S21K00 |
| **Product Family** | ThinkPad T14 Gen 2i |
| **Platform** | x86_64-linux |

## Device Identity

| Identifier | Value |
|------------|-------|
| **Machine ID** | `e4af9ba42d8f4d90a500b1917947339f` |
| **MTM (Machine Type-Model)** | 20W1S21K00 |
| **Product SKU** | LENOVO_MT_20W1_BU_Think_FM_ThinkPad T14 Gen 2i |
| **WiFi MAC** | `a0:e7:0b:25:b5:93` |
| **Bluetooth MAC** | `a0:e7:0b:25:b5:97` |
| **SSD Serial** | 213933803774 |
| **Battery Serial** | 1706 |
| **BIOS Version** | N34ET53W (1.53) |
| **BIOS Date** | 08/31/2022 |

> **Note:** Serial numbers are stored here for device identification during future swaps/replacements. The system serial number is not exposed via sysfs for security reasons.

## Processor

| Specification | Details |
|---------------|---------|
| **CPU** | 11th Gen Intel Core i5-1145G7 |
| **Base Frequency** | 2.60 GHz |
| **Architecture** | x86_64 (Intel Tiger Lake) |
| **Cores/Threads** | 4 Cores / 8 Threads |
| **Microcode Updates** | Enabled (Intel) |
| **Virtualization** | KVM-Intel enabled |

## Memory

| Specification | Details |
|---------------|---------|
| **Total RAM** | 24 GB (22.6 GiB usable) |
| **Type** | DDR4-3200 |
| **Speed** | 3200 MT/s (1600 MHz clock) |
| **Configuration** | 8 GB Soldered (Onboard) + 16 GB SO-DIMM |
| **Slots Populated** | 2 of 2 |
| **SO-DIMM Slot** | 1x DDR4-3200 SO-DIMM (upgradeable) |
| **Max Supported** | 48 GB (8 GB soldered + 32 GB SO-DIMM) |
| **Memory Channels** | Dual Channel |
| **Form Factor** | 260-pin SO-DIMM |

## Storage

| Specification | Details |
|---------------|---------|
| **Primary SSD** | Western Digital PC SN730 NVMe |
| **Capacity** | 512 GB |
| **Interface** | NVMe PCIe |
| **Root Filesystem** | ext4 |
| **Boot Partition** | vfat (EFI) |
| **Swap** | Enabled (separate partition) |

## Graphics

| Specification | Details |
|---------------|---------|
| **GPU** | Intel Iris Xe Graphics |
| **Type** | Integrated (11th Gen Core) |
| **Vendor ID** | 0x8086 (Intel) |

## Display & Input

| Feature | Status |
|---------|--------|
| **TrackPoint** | Enabled with wheel emulation |
| **TouchPad** | Supported |
| **Fingerprint** | Synaptics Prometheus MIS (06cb:00bd) |
| **Desktop Environment** | KDE Plasma 6 |
| **Display Manager** | SDDM |
| **X11** | Enabled |

## Camera

| Specification | Details |
|---------------|---------|
| **Model** | Chicony Electronics Integrated Camera |
| **USB ID** | 04f2:b6d0 |
| **Connection** | USB 2.0 High Speed (480 Mbps) |
| **Device Path** | /dev/video0 |
| **V4L2 Support** | Yes (capture capable) |

## Connectivity

| Feature | Specification |
|---------|-------------|
| **Thunderbolt** | Enabled (initrd) |
| **USB** | USB 3.2 / USB-C |
| **Network** | NetworkManager |
| **Bluetooth** | Intel AX201/AX211 (btusb/btintel) |
| **Audio** | PipeWire with PulseAudio compatibility |
| **Printing** | CUPS enabled |

## Power

| Specification | Details |
|---------------|---------|
| **Battery Model** | 5B10W51827 |
| **Type** | Internal Lithium Polymer |

## Boot & Firmware

| Specification | Details |
|---------------|---------|
| **Boot Loader** | systemd-boot |
| **Firmware** | UEFI |
| **EFI Variables** | Accessible |
| **Secure Boot** | Not enabled (standard NixOS) |

## Kernel & Modules

```
Available Kernel Modules:
- xhci_pci (USB 3.0)
- thunderbolt
- nvme (NVMe storage)
- usb_storage
- sd_mod (SD cards)
- sdhci_pci (SD host controller)
- kvm-intel (Intel virtualization)
- btusb (Bluetooth USB driver)
```

## Software Environment

| Category | Details |
|----------|---------|
| **OS** | NixOS 25.11 (Vicuna) |
| **Kernel** | Linux (latest stable) |
| **Flakes** | Enabled |
| **Home Manager** | Integrated as NixOS module |
| **Locale** | en_IN (English - India) |
| **Timezone** | Asia/Kolkata (IST) |

## Enabled Features

- ✅ KDE Plasma 6 Desktop
- ✅ PipeWire Audio (ALSA/Pulse compatible)
- ✅ Docker Virtualization
- ✅ TrackPoint with wheel emulation
- ✅ 1Password GUI & CLI
- ✅ Google Chrome
- ✅ VS Code
- ✅ Firefox
- ✅ RustDesk
- ✅ OpenCode
- ✅ Fingerprint sensor (fprintd)
- ✅ Bluetooth (Intel AX201/AX211)
- ✅ NetworkManager
- ✅ Printing support (CUPS)

---

*Generated for NixOS configuration repository*
