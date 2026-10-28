# Fedora MangoWM Remix

A complete, reproducible Fedora 44 desktop: **MangoWM** (a Wayland compositor) with a
**hand-written Quickshell shell**, a Waybar dock, a custom login screen, systemd-boot,
and a uniform monochrome theme with JetBrains Mono everywhere.

![The desktop: bar, dock, app launcher, dashboard, control center, shortcut cheatsheet and fastfetch](docs/demo.gif)

<sub>Shown with Fedora 44's default wallpaper (CC BY-SA 4.0, Fedora Design Team). The theme colors are generated from whatever wallpaper you pick.</sub>

This repo can rebuild that desktop two ways:

1. **An install ISO** (`build-iso.sh`): boot it, click through Fedora's normal graphical
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
| **Dock** | Part of the shell (`dock/`): left edge, intelligent auto-hide, one icon per app with a running indicator. Click focuses / minimizes / restores, middle click closes, **right click → Pin to dock / Unpin, New window, Close** |
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
| `Super + Shift + P` | Pin / unpin the focused app to the dock |

---

## Option 1: install from the ISO

### Download it

The ISO is on the [Releases page](https://github.com/mbodigi/fedora-mangowm-remix/releases):
`fedora-mangowm-remix-VERSION-x86_64.iso` (about 1.2 GB), with its `.sha256`. Check it before
writing it to a USB stick:

```bash
sha256sum -c fedora-mangowm-remix-VERSION-x86_64.iso.sha256
```

Or with **BitTorrent**: open the release's `.torrent` (or the magnet link below) in any torrent
client (qBittorrent, Transmission…). GitHub is built in as a web seed, so it works even when nobody
else is seeding.

```
magnet:?xt=urn:btih:9d0b5bba70f480c985ba05e9432c091ee52dde99&dn=fedora-mangowm-remix-44.2&tr=udp%3A%2F%2Ftracker.opentrackr.org%3A1337%2Fannounce&tr=udp%3A%2F%2Fopen.stealth.si%3A80%2Fannounce&tr=udp%3A%2F%2Ftracker.torrent.eu.org%3A451%2Fannounce&tr=udp%3A%2F%2Fexodus.desync.com%3A6969%2Fannounce&ws=https%3A%2F%2Fgithub.com%2Fmbodigi%2Ffedora-mangowm-remix%2Freleases%2Fdownload%2F
```

It's Fedora's official net-install image (for its installer) with this repo's kickstart and
configs added, so the installer screens still say Fedora. **The packages (about 2.5 GB) download
during the install**, so it needs internet. For an install without internet, build the offline
variant yourself (below). Or build either one yourself:

### Build the ISO

Requirements: Fedora with `podman` and `curl`, about 3 GB of free disk space (12 GB for the offline
variant), and an internet connection.

```bash
git clone https://github.com/mbodigi/fedora-mangowm-remix.git
cd fedora-mangowm-remix
./build-iso.sh
```

What `build-iso.sh` does:

1. Runs `pack.sh`, which turns `setup/` into `build/shell-setup.ks` (the installer instructions)
   and `build/shell-bundle.tar.gz` (the configs).
2. Downloads Fedora's **official** net-install ISO (`Fedora-Everything-netinst-x86_64-44-1.7.iso`, 1.2 GB)
   and checks it against Fedora's **GPG-signed checksum** file. It stops if the check fails.
3. Builds a small container image with Fedora's ISO tools (lorax, pykickstart, xorriso), once.
4. Offline variant only (`OFFLINE=1`): runs `src/make-repo.sh` in a clean Fedora container with the same repos as the installed system:
   downloads every package in `setup/packages.txt` (plus the GRUB/shim bootloader packages for
   Secure Boot and BIOS machines) with all dependencies into `download/rpms/`, and makes
   `build/shellrepo/` a package repo with Fedora's package groups.
5. Validates the kickstart with `ksvalidator`.
6. Runs `mkksiso` to add the kickstart and the bundle (plus the package repo, offline) to the ISO,
   and points all boot menus (BIOS, UEFI and the UEFI boot image) at them (`inst.ks=…`, and offline
   `inst.repo=hd:LABEL=…:/shellrepo`). This step needs root (it uses a loop device), so a password
   prompt appears.

Result: `out/fedora-mangowm-remix-VERSION-x86_64-personal.iso` (about 1.2 GB; `VERSION` is in the
file of that name, e.g. `44.2`). With `OFFLINE=1 ./build-iso.sh` you get
`…-x86_64-offline-personal.iso` instead (about 3.8 GB, every package on it, no internet needed to install). With `PUBLIC=1 ./build-iso.sh` it leaves out the local wallpapers
(`private/`) and writes `out/fedora-mangowm-remix-VERSION-x86_64.iso` instead; that's the one
published on the Releases page. `./release.sh` then prepares it for GitHub (one file; an offline ISO, which is
over GitHub's 2 GB limit, in parts) and makes its checksum and torrent in `out/release/`, for a release tagged `fedora-mangowm-remix-VERSION`.

### Write it to a USB stick

Use a 2 GB or bigger stick (8 GB for the offline variant), with **Fedora Media Writer** or `dd` (this erases the stick; double-check the device name with `lsblk`):

```bash
sudo dd if=fedora-mangowm-remix-VERSION-x86_64.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

### Install

1. Boot the USB stick (it works on UEFI and old BIOS PCs, with or without Secure Boot).
2. Pick **Install Fedora 44** in the boot menu.
3. In the installer fill in only these screens:
   - **Installation Destination**: pick the disk (Automatic partitioning is fine)
   - **Network & Host Name**: a cable connects by itself; for Wi-Fi, pick your network here
     (the packages download during the install; offline variant: optional)
   - **Time & Date**: your time zone
   - **User Creation**: your username and password; tick **Make this user administrator**
4. **Do not change Software Selection.** It must say *Custom software selected*. Choosing an
   environment there replaces this setup's package list.
5. Click **Begin Installation**. The packages download from the internet (about 2.5 GB), then
   everything is set up. The offline variant installs from the USB stick instead (about 17 minutes
   in a test VM).
6. Reboot: systemd-boot, then the login screen, then the desktop.

### What the installer does

- **Packages**: downloaded during the install from the same repos the installed system uses (the
  offline variant installs them from `/shellrepo` on the ISO): Fedora + updates, RPM Fusion free/nonfree, terra (MangoWM, Ghostty,
  VSCodium), the official [Quickshell COPR](https://copr.fedorainfracloud.org/coprs/errornointernet/quickshell),
  Brave, LibreWolf and Cisco OpenH264.
- **Network**: DHCP on a connected cable; Wi-Fi can be set up in the installer, and that
  connection is copied to the new system. NetworkManager's connectivity
  check is installed, so the shell notices Wi-Fi login pages.
- **Bootloader**, picked per machine in the kickstart `%pre`:
  - UEFI with Secure Boot **off**: **systemd-boot**
  - UEFI with Secure Boot **on**: GRUB through Fedora's signed shim (systemd-boot from Fedora isn't signed)
  - Old BIOS: GRUB
- **After the packages** (`%post`): copies the system files from `setup/root` (as root, without
  touching existing folders like `/` or `/etc`), creates the `greeter` account the login screen
  runs as, enables the greetd login screen, and gives every user created in the installer the configs from `setup/home`
  (via `shell-user-setup`, which fills in the user's real home folder).
- **First login**: `shell-firstlogin` applies the settings that live in dconf (GTK theme, icons,
  fonts, Celluloid options), once.

The ISO's own boot menu is GRUB. That's Fedora's install media, and it's what lets the same
ISO boot on BIOS, UEFI and Secure Boot machines. It doesn't affect the installed system.

---

## Option 2: set up an existing Fedora 44

On a fresh Fedora 44 (any edition or spin), as your normal user:

```bash
git clone https://github.com/mbodigi/fedora-mangowm-remix.git
cd fedora-mangowm-remix
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
| `./test-vm.sh install` | Fully automatic test install on a 30 GB virtual disk with **no network** (user `test`, password `test`) |
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
├── VERSION               release version (Fedora release . build), used in every file name
├── release.sh            split the public ISO for GitHub + checksum + torrent
├── build-iso.sh          official Fedora netinst ISO + kickstart + bundle + package repo -> out/*.iso
├── install.sh            apply the setup to an existing Fedora 44
├── test-vm.sh            try the ISO in a VM
├── src/make-torrent.py   .torrent of a release's files, with GitHub as a web seed
├── src/
│   ├── shell-setup.ks.in kickstart template (@PACKAGES@ is filled in by pack.sh)
│   ├── repos-online.ks   the repos a net-install downloads from (default)
│   ├── repos-offline.ks  … or the repo on the ISO (OFFLINE=1)
│   ├── make-repo.sh      offline: downloads every package into the on-ISO repo (runs in a container)
│   ├── offline-extra-packages.txt  bootloaders the installer may need (GRUB, shim)
│   ├── system/           sysusers.d / tmpfiles.d for the login screen's account
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
wallpaper: pick one with `Super + Y` (the dashboard can search and download from wallhaven; wallpapers live in the hidden
`~/.local/share/wallpapers/`),
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
- Demo GIF wallpaper: Fedora 44 default background by the Fedora Design Team, [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/)
- Built on [Fedora](https://fedoraproject.org) 44
