# Vayu Linux

A complete Fedora 44 desktop, built as a remix of Fedora: **MangoWM** (a Wayland compositor) with a **hand-written Quickshell
shell**, a dock with app pinning, a custom login screen, and a uniform monochrome theme with
JetBrains Mono everywhere.

![The desktop: bar, dock, app launcher, dashboard, control center, shortcut cheatsheet and fastfetch](docs/demo.gif)

<sub>Shown with Fedora 44's default wallpaper (CC BY-SA 4.0, Fedora Design Team). The theme colors are generated from whatever wallpaper you pick.</sub>

## Install

On a **fresh Fedora 44 Everything install with no desktop**: boot the
[Everything netinst ISO](https://fedoraproject.org/misc/#everything), and in the installer's
Software Selection pick **Minimal Install** (no desktop environment). Then log in as your normal user and run:

```bash
curl -fsSL https://raw.githubusercontent.com/mbodigi/fedora-mangowm-remix/main/get.sh | bash
```

Then reboot, pick the **Mango** session on the new login screen, and log in.

- It asks for your **password once** (sudo) and downloads about **2.5 GB** of packages.
- Fedora Workstation, KDE and other editions or spins (anything with a desktop already) aren't
  supported: start from Everything with no desktop.
- **Bootloader:** where it's safe (UEFI, Secure Boot off, no Windows on the disk) it switches to
  **systemd-boot**, like the original machine, and keeps GRUB as a fallback entry in your PC's boot
  menu. Otherwise GRUB stays, with a message saying why. `… | SDBOOT=0 bash` keeps GRUB.
- Want to read it first? `get.sh` just downloads this repo and runs [`install.sh`](install.sh),
  which is short. Or clone the repo and run `./install.sh` yourself.
- A specific version: `curl -fsSL …/get.sh | REF=<tag or branch> bash`.

### What the installer does

1. Adds the repos: RPM Fusion free/nonfree, terra (MangoWM, Ghostty, VSCodium), the official
   [Quickshell COPR](https://copr.fedorainfracloud.org/coprs/errornointernet/quickshell), Brave and LibreWolf.
2. Swaps Fedora's `ffmpeg-free` for RPM Fusion's full `ffmpeg`, then installs the package list
   from [`setup/packages.txt`](setup/packages.txt). Skipped: the original machine's Fedora release package, kernels
   (Fedora's own are used) and installer leftovers.
3. Switches to systemd-boot where it's safe (see above): sdubby in place of grubby, `bootctl install`,
   kernels as boot entries on the EFI partition (without the rescue image, which doesn't fit there).
4. Copies the system files from `setup/root` as root, without changing existing folders like `/` or `/etc`:
   the login screen, browser policies, LibreWolf defaults, battery rule, tuned profile, helper scripts.
5. Creates the `greeter` account the login screen runs as, and enables greetd.
6. Gives your user the configs from `setup/home` (existing files of yours are kept, not overwritten).
7. At your first login, `shell-firstlogin` applies the settings that live in dconf (GTK theme, icons, fonts, Celluloid).

No wallpapers are included (they're other people's art); pick one with `Super + Y`. The dashboard can
search and download from wallhaven, into the hidden `~/.local/share/wallpapers/`.

## What you get

| Part | What it is |
|---|---|
| **Window manager** | [MangoWM](https://github.com/mangowm/mango) 0.18 (from the terra repo), tiling + floating, scenefx effects |
| **Shell** | Our own [Quickshell](https://quickshell.org) shell (`setup/home/.config/quickshell/shell`): bar, app launcher, clipboard history, notifications + center, control center (with a sound output/input drop-down), OSD, lock screen, dashboard with wallpapers, power menu, cheatsheet, task manager, settings panel, polkit password dialog, battery warnings, Wi-Fi login (captive portal) notification |
| **Dock** | Part of the shell (`dock/`): left edge, intelligent auto-hide, one icon per app with a running indicator. Click focuses / minimizes / restores, middle click closes, **right click → Pin to dock / Unpin, New window, Close** |
| **Login screen** | A Quickshell greeter run by greetd (`setup/root/usr/local/share/shell-greeter`) |
| **Theme** | Colors generated from the wallpaper by matugen (monochrome scheme), applied to the shell, GTK 3/4, Qt 5/6 and Mango; accents are fixed soft grays (#505050 / #8a8a8a) |
| **Fonts** | JetBrains Mono for the UI, monospace and subtitles (fontconfig maps sans-serif to it too) |
| **Browsers** | LibreWolf (default browser, follows the GTK theme, hardware video decoding, compact UI); Brave for web apps, with a policy file that turns off rewards, wallet, VPN, AI, news, telemetry and promos |
| **Video** | Celluloid + mpv with Intel VA-API hardware decoding, full ffmpeg from RPM Fusion |
| **Laptop** | tuned with a custom `laptop-battery` profile; ThinkPad battery charge kept between 75 and 80% (udev rule; harmless on other machines) |

The full package list is in [`setup/packages.txt`](setup/packages.txt) (about 1,800 packages; a few machine-specific ones are skipped on install).

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
├── install.sh            installs the setup on a stock Fedora 44
├── collect.sh            snapshot this machine's setup into setup/ (read-only on the system)
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
- Built on [Fedora](https://fedoraproject.org) 44. This is an unofficial remix, not a Fedora Project release.
