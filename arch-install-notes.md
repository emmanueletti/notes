# Arch installation notes

[Arch installation wiki](https://wiki.archlinux.org/title/Installation_guide)

## Manual installation

### Prerequsites

[ ] Turn off secure boot

### Creating partitions

Layout
- `boot/efi` (formatted FAT32)
- `/boot` boot partision (formatted ext4)
- `/` root partition (formatted btrfs)


### Definitions

**ESP: EFI System Partition**

A partition used to store files needed by the UEFI firmware (BIOS on older devices) to launch bootloaders. Formatted as FAT32 to make it OS agnostic.

## Setting up via archinstall

Clean base for own install script (fw13).

Goal: archinstall does disk/bootloader/kernel/locale/base packages only. Own install script owns the desktop layer (Hyprland, theming, seat access, network daemon) after first boot, similar to how Omarchy's install.sh works.

Walking the guided menu in order:

**Archinstall language**: English, default, no change needed.

**Locales**: keyboard layout `us`, encoding `UTF-8`, system language `en_US.UTF-8`.

**Mirrors and repositories**: region Canada, no custom mirrors/repos.

**Disk configuration**: single disk, no LVM (btrfs subvolumes give the resize flexibility LVM would, one less layer to reason about during recovery):
- `/boot` 1GiB fat32, boot flag
- `/` 19GiB btrfs, `compress=zstd`, LUKS-encrypted (plain LUKS, not LUKS-on-LVM)
- subvolumes: `@` -> `/`, `@home` -> `/home`, `@log` -> `/var/log`, `@pkg` -> `/var/cache/pacman/pkg`
- btrfs snapshots: Snapper (pairs with `snap-pac` post-install for pacman pre/post-transaction snapshots)
- disk encryption: LUKS, default iteration time (10000ms) fine as-is

**Swap**: zram, `zstd` compression, enabled. No separate swap partition needed alongside it.

**Bootloader**: Limine.

**Kernels**: `linux` + `linux-lts` as a fallback (lts is the safer backup pick vs `linux-zen` -- zen shares most of mainline's codebase/timing so a bad mainline update often breaks it too; lts is the actually-frozen branch).

**Hostname**: `fw13` (drop generic prefixes like "box", just the device model, resolves as `fw13.local`).

**Authentication**: set a root password and/or create a sudo user here -- archinstall won't let you confirm install without it. Not pre-decided, do it live during install (don't forget it, screenshots so far haven't shown this step being completed).

**Profile**: **Minimal**, not Desktop/Hyprland. Picking Hyprland as the archinstall profile pulls generic waybar/seat_access/greeter config that a follow-up install script would just fight or overwrite. Minimal also means no greeter/sddm gets installed -- matches an autologin-to-Hyprland-via-TTY model (no display manager at all) if that's what the script sets up.

**Applications**: kept, independent of profile, no conflict with a follow-up script since installing/enabling them is idempotent:
- audio: pipewire
- bluetooth: enabled
- firewall: ufw
- fonts: noto-fonts, noto-fonts-emoji, ttf-liberation
- print service: enabled

**Network configuration**: **Copy ISO network config**, not NetworkManager. Leaves the network layer untouched for the install script to set up (e.g. bare `iwd` + an `iwd`-native TUI like impala), rather than pre-installing NetworkManager that the script then has to remove/fight.

**Pacman**: `color: true`, `parallel_downloads: 5`.

**Additional packages**: bare minimum to bootstrap a personal install script afterward -- `git`, `base-devel` (needed to build an AUR helper like paru/yay). Add `curl`/`wget` only if the script's bootstrap step needs them directly instead of `git clone`.

**Timezone**: Canada/Eastern.

**Automatic time sync (NTP)**: enabled.

### Reference: what a script like Omarchy's install.sh sets up after base Arch

- mandatory LUKS full-disk encryption, auto-login straight into Hyprland after passphrase entry -- no display manager/greeter
- Plymouth boot splash themed to match the desktop theme
- `ufw` firewall enabled by default
- `seatd` for seat management (no DM to hand off the session to)
- bare `iwd` for wifi + a TUI (impala) for connecting, not NetworkManager
- `pipewire` for audio
- full Hyprland config: keybindings, waybar, notifications (mako), hyprlock, hypridle
- a switchable theme system restyling terminal/nvim/btop/waybar/lockscreen/Plymouth together
- bootstraps an AUR helper (paru) for anything not in the main repos
- config split: personal tweaks in `~/.config`, the script's own managed files under `~/.local/share/<script-name>`
