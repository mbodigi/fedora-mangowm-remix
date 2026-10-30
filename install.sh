#!/bin/bash
# Turn a fresh Fedora 44 Everything install with no desktop (Minimal Install) into this desktop. Usually run through get.sh:
#   curl -fsSL https://raw.githubusercontent.com/mbodigi/fedora-mangowm-remix/main/get.sh | bash
# or from a clone of this repo: ./install.sh
# Asks for your password once (sudo) and needs internet (~2.5 GB of packages). Editions or spins
# that already have a desktop (Workstation, KDE…) aren't supported. Where it's
# safe (UEFI, Secure Boot off, no Windows), systemd-boot becomes the bootloader, with GRUB kept as a
# fallback boot entry; SDBOOT=0 keeps GRUB.
set -euo pipefail
cd "$(dirname "$0")"
[ -f setup/packages.txt ] || { echo "setup/ is missing" >&2; exit 1; }
[ "$(rpm -E %fedora)" = 44 ] || { echo "This setup was made for Fedora 44." >&2; exit 1; }

me=$(id -un)

# Packages from the original machine that must not land on someone else's Fedora:
# its bootloader tooling (sdubby replaces grubby, which Fedora's GRUB needs for new kernels),
# its fedora-release package, its Secure Boot key tool (sbctl), and installer/live-image leftovers. Kernels come from Fedora as usual.
skip='^(sdubby|systemd-boot-unsigned|fedora-release.*|kernel.*|anaconda.*|libreport-anaconda|dracut-live|livesys-scripts|initial-setup.*|plymouth-theme-.*|gpg-pubkey|sbctl)$'
pkgs=$(grep -vE "$skip" setup/packages.txt | tr '\n' ' ')

echo "Installing Vayu Linux for $me…"
sudo SDBOOT="${SDBOOT:-1}" bash -euo pipefail -s "$PWD" "$me" "$pkgs" <<'EOF'
R=$1; user=$2; pkgs=$3
# many downloads at once (dnf's default is 3) and the fastest mirrors: ~2.5 GB goes much faster.
# No weak deps: packages.txt already lists the recommended packages the setup really uses; dnf's
# default would add optional extras on top (SciPy, TeX Live, Docker…) that it doesn't.
dnf() { command dnf --setopt=max_parallel_downloads=15 --setopt=fastestmirror=True --setopt=install_weak_deps=False "$@"; }

# repos: RPM Fusion and terra from their release packages, the rest are plain .repo files
dnf -y install \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-44.noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-44.noarch.rpm"
rpm -q terra-release >/dev/null || dnf -y install --nogpgcheck --repofrompath "terra,https://repos.fyralabs.com/terra44" terra-release
cp "$R"/setup/root/etc/yum.repos.d/*.repo /etc/yum.repos.d/

# the full ffmpeg from RPM Fusion instead of Fedora's ffmpeg-free (the one swap this does)
if rpm -q ffmpeg-free >/dev/null; then dnf -y swap ffmpeg-free ffmpeg --allowerasing; fi
dnf -y install --skip-unavailable $pkgs

# system files, owned by root; existing directories (/, /etc, /usr...) keep their owner and mode
(cd "$R/setup/root" && tar -cf - --owner=0 --group=0 --numeric-owner .) | tar -xf - -C / --no-overwrite-dir
rm -rf /usr/share/shell-setup && mkdir -p /usr/share/shell-setup
cp -r "$R/setup/home" "$R/setup/greeter-cache" /usr/share/shell-setup/
if [ -d "$R/private" ]; then cp -r "$R/private/." /usr/share/shell-setup/; fi
chown -R root:root /usr/share/shell-setup

# the login screen's account and its home (before users get the greeter cache)
systemd-sysusers shell-greeter.conf
systemd-tmpfiles --create shell-greeter.conf
semanage fcontext -a -t cache_home_t '/var/cache/shell-greeter(/.*)?' 2>/dev/null || true
restorecon -RF /etc /usr/local /usr/share/shell-setup /usr/share/librewolf /var/lib/greeter 2>/dev/null || true

# login screen: our greeter (and no other display manager, in case one got installed)
for dm in gdm sddm lightdm lxdm; do systemctl disable "$dm" 2>/dev/null || true; done
systemctl enable greetd

# sched_ext scheduler (scx_lavd --autopower, see /etc/scx_loader/config.toml): follows the power profile.
# It needs /boot/config-<version>; /etc/kernel/install.d/50-boot-config.install copies it for new
# kernels, this does it for the ones already installed (GRUB installs have it already).
for k in /usr/lib/modules/*/config; do v=$(basename "$(dirname "$k")"); [ -e "/boot/config-$v" ] || cp "$k" "/boot/config-$v"; done
systemctl enable scx_loader
systemctl set-default graphical.target

/usr/local/bin/shell-user-setup "$user"

# Bootloader: systemd-boot like the original machine, where that's safe. GRUB stays installed as a
# fallback boot entry; systemd-boot just goes first in the firmware's boot order.
# Kept on GRUB: BIOS machines, Secure Boot on (Fedora's systemd-boot isn't signed), Windows on the
# EFI partition (GRUB is what lists it), too little space on the EFI partition, or SDBOOT=0.
sdboot_ok() {
    [ "$SDBOOT" != 0 ] || { echo "SDBOOT=0: keeping GRUB"; return 1; }
    [ -d /sys/firmware/efi ] || { echo "BIOS machine: keeping GRUB"; return 1; }
    sb=$(od -An -t u1 /sys/firmware/efi/efivars/SecureBoot-8be4df61-93ca-11d2-aa0d-00e098032b8c 2>/dev/null | awk '{print $NF}')
    [ "$sb" != 1 ] || { echo "Secure Boot is on: keeping GRUB (systemd-boot isn't signed)"; return 1; }
    mountpoint -q /boot/efi || { echo "no EFI partition at /boot/efi: keeping GRUB"; return 1; }
    [ ! -d /boot/efi/EFI/Microsoft ] || { echo "Windows found on the EFI partition: keeping GRUB"; return 1; }
    free_mb=$(df -m --output=avail /boot/efi | tail -1)
    [ "$free_mb" -ge 300 ] || { echo "only ${free_mb} MB free on the EFI partition: keeping GRUB"; return 1; }
}
if sdboot_ok; then
    echo "Switching to systemd-boot…"
    if rpm -q grubby >/dev/null; then dnf -y swap grubby sdubby; else dnf -y install sdubby; fi
    dnf -y install systemd-boot-unsigned
    # kernels go on the EFI partition as boot-loader entries; no rescue image (it doesn't fit there)
    printf 'layout=bls\nBOOT_ROOT=/boot/efi\n' > /etc/kernel/install.conf
    echo 'dracut_rescue_image="no"' > /etc/dracut.conf.d/90-no-rescue.conf
    [ -s /etc/kernel/cmdline ] || sed -E 's/(^| )(BOOT_IMAGE|initrd)=[^ ]*//g; s/^ +//' /proc/cmdline > /etc/kernel/cmdline
    bootctl install --esp-path=/boot/efi
    for k in /usr/lib/modules/*/vmlinuz; do kernel-install add "$(basename "$(dirname "$k")")" "$k"; done
    printf 'timeout 3\ndefault @saved\n' > /boot/efi/loader/loader.conf
    n=$(ls /boot/efi/loader/entries/*.conf 2>/dev/null | wc -l)
    [ "$n" -gt 0 ] && echo "systemd-boot installed with $n kernel entries (GRUB kept as a fallback boot entry)"
fi
EOF

echo
echo "Done. Reboot to get the new login screen; pick the Mango session and log in."
