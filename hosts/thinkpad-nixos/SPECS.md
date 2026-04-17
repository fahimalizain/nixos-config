# ThinkPad T14 Gen 2i - System Specifications

## Hardware Overview

| Component | Specification |
|-----------|-------------|
| **Model** | Lenovo ThinkPad T14 Gen 2i |
| **Machine Type** | 20W1S21K00 |
| **Product Family** | ThinkPad T14 Gen 2i |
| **Platform** | x86_64-linux |

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
| **Total RAM** | ~24 GB |
| **Type** | DDR4 (Soldered + SO-DIMM) |

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
| **Desktop Environment** | KDE Plasma 6 |
| **Display Manager** | SDDM |
| **X11** | Enabled |

## Connectivity

| Feature | Specification |
|---------|-------------|
| **Thunderbolt** | Enabled (initrd) |
| **USB** | USB 3.2 / USB-C |
| **Network** | NetworkManager |
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
- ✅ NetworkManager
- ✅ Printing support (CUPS)

---

*Generated for NixOS configuration repository*
