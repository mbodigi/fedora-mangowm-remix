#!/bin/bash
# Fallback: turn a stock Fedora 44 install into this desktop, without the ISO.
# Run as your normal user from a clone of this repo:
#   ./install.sh
# It asks for your password once (sudo) and needs internet.
set -euo pipefail
cd "$(dirname "$0")"
OUT=build
./pack.sh
[ "$(rpm -E %fedora)" = 44 ] || { echo "this setup was made for Fedora 44"; exit 1; }

me=$(id -un)
tmp=$(mktemp -d)
tar -xzf "$OUT/shell-bundle.tar.gz" -C "$tmp"

sudo bash -euxo pipefail -s "$tmp" "$me" "$PWD/setup/packages.txt" <<'EOF'
B=$1; user=$2; list=$3
# repos: RPM Fusion and terra from their release packages, the rest are plain .repo files in the bundle
dnf -y install \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-44.noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-44.noarch.rpm"
dnf -y install --nogpgcheck --repofrompath "terra,https://repos.fyralabs.com/terra44" terra-release
cp -a "$B/root/etc/yum.repos.d/." /etc/yum.repos.d/
dnf -y swap ffmpeg-free ffmpeg --allowerasing || true
dnf -y install --allowerasing $(cat "$list")

cp -a "$B/root/." /
mkdir -p /usr/share/shell-setup
cp -a "$B/home" "$B/greeter-cache" /usr/share/shell-setup/
semanage fcontext -a -t cache_home_t '/var/cache/shell-greeter(/.*)?' || true
restorecon -RF /etc /usr/local /usr/share/shell-setup /usr/share/librewolf || true

# login screen: our greeter instead of whatever display manager the spin shipped
for dm in gdm sddm lightdm lxdm; do systemctl disable "$dm" 2>/dev/null || true; done
systemctl enable greetd
systemctl set-default graphical.target

/usr/local/bin/shell-user-setup "$user"
EOF
rm -rf "$tmp"
echo "Done. Reboot to get the login screen and the desktop."
