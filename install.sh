#!/bin/bash
# Turn a stock Fedora 44 (any edition or spin) into this desktop. Usually run through get.sh:
#   curl -fsSL https://raw.githubusercontent.com/mbodigi/fedora-mangowm-remix/main/get.sh | bash
# or from a clone of this repo: ./install.sh
# Asks for your password once (sudo), needs internet (~2.5 GB of packages), and removes nothing:
# Fedora's own bootloader, edition and desktop stay; the MangoWM login session is added next to them.
set -euo pipefail
cd "$(dirname "$0")"
[ -f setup/packages.txt ] || { echo "setup/ is missing" >&2; exit 1; }
[ "$(rpm -E %fedora)" = 44 ] || { echo "This setup was made for Fedora 44." >&2; exit 1; }

me=$(id -un)

# Packages from the original machine that must not land on someone else's Fedora:
# its bootloader tooling (sdubby replaces grubby, which Fedora's GRUB needs for new kernels),
# its edition identity, and installer/live-image leftovers. Kernels come from Fedora as usual.
skip='^(sdubby|systemd-boot-unsigned|fedora-release.*|kernel.*|anaconda.*|libreport-anaconda|dracut-live|livesys-scripts|initial-setup.*|plymouth-theme-.*|gpg-pubkey)$'
pkgs=$(grep -vE "$skip" setup/packages.txt | tr '\n' ' ')

echo "Installing the Fedora MangoWM Remix setup for $me…"
sudo bash -euo pipefail -s "$PWD" "$me" "$pkgs" <<'EOF'
R=$1; user=$2; pkgs=$3
# many downloads at once (dnf's default is 3) and the fastest mirrors: ~2.5 GB goes much faster
dnf() { command dnf --setopt=max_parallel_downloads=15 --setopt=fastestmirror=True "$@"; }

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

# login screen: our greeter instead of the edition's display manager (which stays installed)
for dm in gdm sddm lightdm lxdm; do systemctl disable "$dm" 2>/dev/null || true; done
systemctl enable greetd
systemctl set-default graphical.target

/usr/local/bin/shell-user-setup "$user"
EOF

echo
echo "Done. Reboot to get the new login screen; pick the Mango session and log in."
echo "To go back to your edition's login screen: sudo systemctl disable greetd && sudo systemctl enable gdm (or sddm)."
