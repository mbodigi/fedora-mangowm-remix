# Vayu Linux

<img src="setup/home/.config/fastfetch/vayu.svg" alt="Vayu Linux logo" width="96" align="right">

**Vayu Linux** is a Linux distribution based on Fedora. It keeps Fedora's packages, repos, kernels and
updates, and adds its own desktop and identity on top: **MangoWM** (a Wayland compositor) with a
**hand-written Quickshell shell**, a dock with app pinning, a custom login screen, a uniform monochrome
theme with JetBrains Mono everywhere, its own name, logo and boot splash, and tuned power and memory settings.

Vayu (वायु) is the Sanskrit name of the wind.

![The desktop: bar, dock, app launcher, dashboard, control center, shortcut cheatsheet and fastfetch](docs/demo.gif)

<sub>Shown with Fedora 44's default wallpaper (CC BY-SA 4.0, Fedora Design Team). The theme colors are generated from whatever wallpaper you pick.</sub>

## How Vayu Linux relates to Fedora

Vayu Linux is a **Fedora derivative**: not a fork that rebuilds Fedora's packages, but a layer on top of a
regular Fedora install. You install Fedora Everything with no desktop, then the installer turns it into
Vayu Linux. What that layer changes:

| Area | What Vayu Linux does |
|---|---|
| **Desktop** | MangoWM, our own Quickshell shell and dock, our own login screen (greetd), matugen theming |
| **Name** | `/etc/os-release` says **Vayu Linux 44** (`NAME`, `PRETTY_NAME`, logo, color), written from Fedora's own file by [`vayu-os-release`](setup/root/usr/local/bin/vayu-os-release) at install, at every boot and before each new kernel gets its boot entry, so a Fedora update or release upgrade that restores the original file doesn't undo it. `ID=fedora` stays, so dnf, repos and scripts that check for Fedora keep working. A default hostname (`fedora`) becomes `vayu`. |
| **Boot** | A Plymouth boot splash with the Vayu logo (`setup/root/usr/share/plymouth/themes/vayu`), Fedora's spinner animation below it; boot menu entries are named Vayu Linux. systemd-boot where it's safe (see Install). |
| **Logo** | [`vayu.svg`](setup/home/.config/fastfetch/vayu.svg), shown by fastfetch and used for the OS icon (`vayu-logo-icon`) |
| **System** | Power profiles that follow the charger, the `scx_lavd` scheduler, zstd-compressed zram swap |
| **Packages** | Extra repos (RPM Fusion, terra, Quickshell COPR, Brave, LibreWolf) and the package list in `setup/packages.txt` |

Everything else (kernel, system libraries, security updates, release upgrades) comes straight from Fedora.
Vayu Linux is an independent project and is not affiliated with or endorsed by the Fedora Project.

## Install

1. Install Fedora from the [Everything ISO](https://fedoraproject.org/misc/#everything), choosing **Minimal Install**.
2. Run:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/mbodigi/vayu-linux/main/get.sh | bash
   ```
3. Reboot.

That's it.

<details>
<summary>Details</summary>

- It asks for your **password once** (sudo) and downloads about **2.5 GB** of packages, plus the Iotas notes app and its GNOME runtime from Flathub.
- Fedora Workstation, KDE and other editions or spins (anything with a desktop already) aren't
  supported: start from Everything with no desktop.
- **Bootloader:** where it's safe (UEFI, Secure Boot off, no Windows on the disk) it switches to
  **systemd-boot**, like the original machine, and keeps GRUB as a fallback entry in your PC's boot
  menu. Otherwise GRUB stays, with a message saying why. `… | SDBOOT=0 bash` keeps GRUB.
- Want to read it first? `get.sh` just downloads this repo and runs [`install.sh`](install.sh),
  which is short. Or clone the repo and run `./install.sh` yourself.
- A specific version: `curl -fsSL …/get.sh | REF=<tag or branch> bash`.

</details>

### What the installer does

1. **Repos:** adds RPM Fusion, terra, the Quickshell COPR, Brave and LibreWolf.
2. **Packages:** installs the package list ([`setup/packages.txt`](setup/packages.txt)) and swaps Fedora's limited ffmpeg for the full one. Kernels stay Fedora's own.
3. **Notes app:** installs Iotas from Flathub, without network access.
4. **System files:** copies the login screen, power profiles, browser policies and helper scripts from [`setup/root`](setup/root).
5. **Branding:** sets the Vayu Linux name, logo and boot splash.
6. **Services:** turns on the login screen, the CPU scheduler and daily firmware update checks, and stops the boot from waiting for the network.
7. **dnf:** sets 15 parallel downloads, no optional extras, no "countme" ping, and skips extra repos that are down.
8. **Your settings:** copies the desktop configs from [`setup/home`](setup/home) to your user, keeping any files you already have.
9. **Bootloader:** switches to systemd-boot with a 1-second menu where it's safe (see Details above), otherwise keeps GRUB.
10. **First login:** applies the theme, icons and fonts.

No wallpapers are included, since they're other people's art. Press `Super + Y` to pick one or download one from wallhaven.

## What you get

- **Window manager:** [MangoWM](https://github.com/mangowm/mango), with tiling and floating windows.
- **Shell:** our own [Quickshell](https://quickshell.org) shell with a bar, app launcher, notifications, quick settings, dashboard, clipboard history, lock screen and task manager.
- **Dock:** on the left edge, hides when a window needs the space; right-click an app to pin it.
- **Login screen:** our own, matching the desktop.
- **Theme:** colors made from your wallpaper, used everywhere (shell, GTK and Qt apps, window borders), with soft grey accents.
- **Font:** JetBrains Mono everywhere.
- **Browsers:** LibreWolf as the default, and Brave for web apps with its extras (rewards, wallet, AI, telemetry) turned off.
- **Notes:** [Iotas](https://flathub.org/apps/org.gnome.World.Iotas), with no network access, so your notes never leave the machine.
- **Video:** Celluloid with hardware decoding and the full ffmpeg.
- **Laptop:** ThinkPad battery charging stops at 80% to make the battery last longer (does nothing on other laptops).

### Performance and power

- **On the charger:** the CPU runs at full speed and the `scx_lavd` scheduler is in performance mode.
- **On battery:** power saving, with the CPU still speeding up when there's work, and `scx_lavd` packs work onto fewer cores so the rest can sleep.
- **Scheduler:** [`scx_lavd`](https://github.com/sched-ext/scx) gives priority to the apps you're using, so the desktop stays smooth under load. It was built for gaming on the Steam Deck; if it ever stops, Linux falls back to its normal scheduler.
- **Boot:** doesn't wait for the network, and the boot menu waits 1 second. On the original ThinkPad X1 Carbon (4th gen), boot went from 25.5 s to 17.7 s.
- **Memory:** compressed swap in RAM (zram with zstd), which fits about 3:1 instead of Fedora's usual 2:1.

The full package list is in [`setup/packages.txt`](setup/packages.txt) (about 1,800 packages).

### Keyboard shortcuts (the most used ones)

| Keys | Action |
|---|---|
| `Super + Enter` | Terminal (Ghostty) |
| `Super + Space` | App launcher |
| `Super + V` | Clipboard history |
| `Super + D` | Dashboard |
| `Super + Y` | Wallpapers |
| `Super + A` | All apps |
| `Super + S` | Quick settings (Wi-Fi, Bluetooth, sound, brightness) |
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


## Keeping the repo up to date (on the original machine)

After changing anything on the desktop:

```bash
./collect.sh      # snapshot the current setup into setup/ (read-only on the system)
git diff          # review what changed
git commit -am "Update setup" && git push
```

`collect.sh` only reads from the system. It copies the configs into `setup/`, rewrites the home
folder path as `@HOME@`, moves helper scripts to `/usr/local/bin`, records every installed package
(checking each one is still available from the repos), and refuses to continue if it finds anything
that looks like a key or password.

## Repo layout

```
.
├── get.sh                the curl one-liner: downloads this repo and runs install.sh
├── install.sh            installs the setup on a stock Fedora
├── collect.sh            snapshot this machine's setup into setup/ (read-only on the system)
├── .github/workflows/    monthly check that every package still exists on the latest stable Fedora
├── src/
│   ├── shell-user-setup  copies the configs to a user, fills in @HOME@
│   ├── shell-firstlogin  dconf settings at first login
│   └── system/           sysusers.d / tmpfiles.d for the login screen's account
├── setup/                the snapshot (generated by collect.sh, committed)
│   ├── packages.txt      every package to install
│   ├── root/             system files, copied to /
│   ├── home/             user configs, copied to your home
│   └── greeter-cache/    login screen colors
└── docs/                 demo GIF, checklist
```

## Credits

- [MangoWM](https://github.com/mangowm/mango), [Quickshell](https://quickshell.org),
  [matugen](https://github.com/InioX/matugen),
  [greetd](https://kl.wtf/projects/greetd)
- [Material Symbols](https://fonts.google.com/icons) font (Apache License 2.0), bundled for the shell's icons
- Demo GIF wallpaper: Fedora 44 default background by the Fedora Design Team, [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/)
- Built on [Fedora](https://fedoraproject.org) 44. Vayu Linux is not a Fedora Project release.
- Boot splash animation: [Plymouth](https://gitlab.freedesktop.org/plymouth/plymouth)'s spinner theme (GPL-2.0), copied from Fedora's package at install time
