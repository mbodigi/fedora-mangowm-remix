# Fedora Shell Setup

A complete, reproducible Fedora 44 desktop: **MangoWM** (a Wayland compositor) with a
**hand-written Quickshell shell**, a Waybar dock, a custom login screen, systemd-boot,
and a uniform monochrome theme with JetBrains Mono everywhere.

This repo can rebuild that desktop two ways:

1. **A net-install ISO** (`build-iso.sh`): boot it, click through Fedora's normal graphical
   installer, and you get this exact desktop on first login.
2. **A script for an existing Fedora 44** (`install.sh`): turns a stock install into this desktop.

No personal data is included: no browser profiles, logins, history, passwords, Wi-Fi keys,
SSH keys or files from the home folder. Only configuration.

---

## What you get

| Part | What it is |
|---|---|
| **Window manager** | [MangoWM](https://github.com/mangowm/mango) 0.18 (from the terra repo), tiling + floating, scenefx effects |
| **Shell** | Our own [Quickshell](https://quickshell.org) shell (`setup/home/.config/quickshell/shell`): bar, app launcher, clipboard history, notifications + center, control center, OSD, lock screen, dashboard with wallpapers, power menu, cheatsheet, task manager, settings panel, polkit password dialog, battery warnings, Wi-Fi login (captive portal) notification |
| **Dock** | Waybar on the left edge, with intelligent auto-hide (`dock-autohide`) |
| **Login screen** | A Quickshell greeter run by greetd (`setup/root/usr/local/share/shell-greeter`) |
| **Theme** | Colors generated from the wallpaper by matugen (monochrome scheme), applied to the shell, GTK 3/4, Qt 5/6 and Mango; accents are fixed soft grays (#505050 / #8a8a8a) |
| **Fonts** | JetBrains Mono for the UI, monospace and subtitles (fontconfig maps sans-serif to it too) |
| **Browsers** | LibreWolf (default browser, follows the GTK theme, hardware video decoding, compact UI); Brave for web apps, with a policy file that turns off rewards, wallet, VPN, AI, news, telemetry and promos |
| **Video** | Celluloid + mpv with Intel VA-API hardware decoding, full ffmpeg from RPM Fusion |
| **Laptop** | tuned with a custom `laptop-battery` profile; ThinkPad battery charge kept between 75 and 80% (udev rule; harmless on other machines) |
| **Boot** | systemd-boot on UEFI (GRUB is used automatically where systemd-boot can't work, see below) |

The full package list is in [`setup/packages.txt`](setup/packages.txt) (about 1,800 packages).

### Keyboard shortcuts (the most used ones)

| Keys | Action |
|---|---|
| `Super + Enter` | Terminal (Ghostty) |
| `Super + Space` | App launcher |
| `Super + V` | Clipboard history |
| `Super + D` | Dashboard |
| `Super + Y` | Wallpapers |
| `Super + A` | Control center (Wi-Fi, audio, brightness…) |
| `Super + ,` | Settings |
| `Super + X` | Power menu |
| `Super + Alt + L` | Lock screen |
| `Super + Shift + /` | Cheatsheet with every shortcut |
| `Super + Q` | Close window |
| `Super + F` / `Super + Shift + F` | Maximize / fullscreen |
| `Super + Shift + Space` | Toggle floating |
| `Super + O` | Overview |
| `Alt + Tab` | Cycle windows |
| `Print` / `Ctrl + Print` / `Alt + Print` | Screenshot region / full screen / window |
| `Ctrl + Alt + Delete` | Task manager |

---

## Option 1: install from the ISO

### Build the ISO

Requirements: Fedora with `podman` and `curl`, about 5 GB of free disk space, and an internet connection.

```bash
git clone https://github.com/mbodigi/fedora-shell-setup.git
cd fedora-shell-setup
./build-iso.sh
```

What `build-iso.sh` does:

1. Runs `pack.sh`, which turns `setup/` into `build/shell-setup.ks` (the installer instructions)
   and `build/shell-bundle.tar.gz` (the configs).
2. Downloads Fedora's **official** net-install ISO (`Fedora-Everything-netinst-x86_64-44-1.7.iso`, 1.2 GB)
   and checks it against Fedora's **GPG-signed checksum** file. It stops if the check fails.
3. Builds a small container image with Fedora's ISO tools (lorax, pykickstart, xorriso), once.
4. Validates the kickstart with `ksvalidator`.
5. Runs `mkksiso` to add the kickstart and bundle to the ISO and point all boot menus
   (BIOS, UEFI and the UEFI boot image) at the kickstart. This step needs root (it uses a loop
   device), so a password prompt appears.

Result: `out/Fedora-Shell-44-netinst.iso` (about 1.2 GB).

### Write it to a USB stick

Use **Fedora Media Writer**, or `dd` (this erases the stick; double-check the device name with `lsblk`):

```bash
sudo dd if=out/Fedora-Shell-44-netinst.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

### Install

1. Boot the USB stick (it works on UEFI and old BIOS PCs, with or without Secure Boot).
2. Pick **Install Fedora 44** in the boot menu.
3. In the installer fill in only these screens:
   - **Installation Destination**: pick the disk (Automatic partitioning is fine)
   - **Network & Host Name**: only needed for Wi-Fi; a cable connects by itself
   - **Time & Date**: your time zone
   - **User Creation**: your username and password; tick **Make this user administrator**
4. **Do not change Software Selection.** It must say *Custom software selected*. Choosing an
   environment there replaces this setup's package list.
5. Click **Begin Installation**. The packages (about 2.5 to 3 GB) are downloaded during the install,
   so it needs a working internet connection (Wi-Fi networks with a login page won't work here).
6. Reboot: systemd-boot, then the login screen, then the desktop.

### What the installer does

- **Repos**: Fedora + updates, RPM Fusion free/nonfree, terra (MangoWM, Ghostty, VSCodium),
  the official [Quickshell COPR](https://copr.fedorainfracloud.org/coprs/errornointernet/quickshell),
  Brave, LibreWolf and Cisco OpenH264.
- **Network**: DHCP on the first connected cable; Wi-Fi can be chosen in the installer. The
  connection used during install is copied to the new system. NetworkManager's connectivity
  check is installed, so the shell notices Wi-Fi login pages.
- **Bootloader**, picked per machine in the kickstart `%pre`:
  - UEFI with Secure Boot **off**: **systemd-boot**
  - UEFI with Secure Boot **on**: GRUB through Fedora's signed shim (systemd-boot from Fedora isn't signed)
  - Old BIOS: GRUB
- **After the packages** (`%post`): copies the system files from `setup/root`, enables the greetd
  login screen, and gives every user created in the installer the configs from `setup/home`
  (via `shell-user-setup`, which fills in the user's real home folder).
- **First login**: `shell-firstlogin` applies the settings that live in dconf (GTK theme, icons,
  fonts, Celluloid options), once.

The ISO's own boot menu is GRUB. That's Fedora's install media, and it's what lets the same
ISO boot on BIOS, UEFI and Secure Boot machines. It doesn't affect the installed system.

---

## Option 2: set up an existing Fedora 44

On a fresh Fedora 44 (any edition or spin), as your normal user:

```bash
git clone https://github.com/mbodigi/fedora-shell-setup.git
cd fedora-shell-setup
./install.sh
```

It asks for your password once, adds the same repos, installs the package list, copies the
system files and your user's configs, switches the login screen to greetd, and tells you to reboot.

---

## Keeping the repo up to date (on the original machine)

After changing anything on the desktop:

```bash
./collect.sh      # snapshot the current setup into setup/ (read-only on the system)
git diff          # review what changed
git commit -am "Update setup" && git push
```

`collect.sh` only reads from the system. It copies the configs into `setup/`, rewrites the home
folder path as `@HOME@`, moves helper scripts to `/usr/local/bin`, records every installed
package (checking each one is still available from the repos), and refuses to continue if it
finds anything that looks like a key or password.

## Testing in a virtual machine

`test-vm.sh` uses libvirt's user session (shows up in virt-manager as *QEMU/KVM User session*):

| Command | What it does |
|---|---|
| `./test-vm.sh try` | Boots the ISO in a UEFI VM up to the installer; nothing is installed |
| `./test-vm.sh install` | Fully automatic test install on a 30 GB virtual disk (user `test`, password `test`) |
| `./test-vm.sh boot` | Starts the installed VM |
| `./test-vm.sh screenshot` | Saves a screenshot of the VM |
| `./test-vm.sh delete` | Removes the VM and its disk |

Needs `virt-install`, `qemu-kvm` and `edk2-ovmf` (UEFI firmware).

---

## Repo layout

```
.
├── collect.sh            snapshot this machine's setup into setup/ (read-only on the system)
├── pack.sh               setup/ -> build/ (kickstart + bundle)
├── build-iso.sh          official Fedora netinst ISO + kickstart + bundle -> out/*.iso
├── install.sh            apply the setup to an existing Fedora 44
├── test-vm.sh            try the ISO in a VM
├── src/
│   ├── shell-setup.ks.in kickstart template (@PACKAGES@ is filled in by pack.sh)
│   ├── shell-user-setup  copies the configs to a user, fills in @HOME@
│   └── shell-firstlogin  dconf settings at first login
└── setup/                the snapshot (generated by collect.sh, committed)
    ├── packages.txt      every package to install
    ├── root/             system files, copied to /
    ├── home/             user configs, copied to each user's home
    └── greeter-cache/    login screen colors
```

Not in the repo (see `.gitignore`): `build/`, `download/`, `out/`, `test/`, and `private/`,
which holds the wallpapers. They're other people's art from [wallhaven](https://wallhaven.cc),
so they're only kept on the original machine. Installs built from a fresh clone start without a
wallpaper: pick one with `Super + Y` (the dashboard can search and download from wallhaven),
and the whole theme is regenerated from it.

## Not carried over

- Browser profiles (bookmarks, logins, extensions' data). Brave's new-tab background color and
  installed web apps live in the profile, so they need to be set once again.
- Personal files, SSH/GPG keys, Wi-Fi passwords, the clipboard history.

## Credits

- [MangoWM](https://github.com/mangowm/mango), [Quickshell](https://quickshell.org),
  [matugen](https://github.com/InioX/matugen), [Waybar](https://github.com/Alexays/Waybar),
  [greetd](https://kl.wtf/projects/greetd)
- [Material Symbols](https://fonts.google.com/icons) font (Apache License 2.0), bundled for the shell's icons
- Built on [Fedora](https://fedoraproject.org) 44
