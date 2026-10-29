#!/bin/bash
# Snapshot this machine's desktop setup (no personal data) into the repo:
#   setup/root/          system files (greeter, greetd, browser policies, LibreWolf defaults, battery rule, tuned, repos, helper scripts)
#   setup/home/          user configs, with the home path written as @HOME@
#   setup/greeter-cache/ the login screen's colors
#   setup/packages.txt   every installed package name (checked to be installable from the repos)
#   private/             wallpapers (other people's art, so not committed; see .gitignore)
# install.sh (or get.sh) installs it on a stock Fedora 44.
# Read-only on the system: everything is copied into this folder.
set -euo pipefail
cd "$(dirname "$0")"
H=$HOME
S=setup
P=private
rm -rf "$S" "$P"
mkdir -p "$S/root" "$S/home" "$S/greeter-cache" "$P/home/.local/share/wallpapers" "$P/greeter-cache"

# ---------- user configs -> setup/home ----------
home_items=(
    .config/mango .config/quickshell/shell .config/quickshell/greeter .config/waybar
    .config/ghostty .config/gtk-3.0 .config/gtk-4.0 .config/qt5ct .config/qt6ct
    .config/fontconfig .config/fastfetch .config/mpv .config/environment.d
    .config/Thunar .config/xfce4 .config/cava
    .config/micro/bindings.json .config/micro/settings.json
    .config/VSCodium/User/settings.json .config/VSCodium/User/keybindings.json .config/VSCodium/User/snippets
    .config/mimeapps.list .config/xdg-terminals.list
    .local/share/applications/brave-browser.desktop
    .local/share/applications/panel-preferences.desktop
    .local/share/color-schemes
    .local/state/shell/settings.json .local/state/shell/colors.json .local/state/shell/wallpaper
)
for p in "${home_items[@]}"; do
    [ -e "$H/$p" ] || continue
    mkdir -p "$S/home/$(dirname "$p")"
    cp -a "$H/$p" "$S/home/$p"
done

# leftovers that aren't setup
find "$S/home" \( -name '*.bak*' -o -name '*.backup*' -o -name '.git' -o -name 'node_modules' \) -prune -exec rm -rf {} +

# portability: helper scripts move to /usr/local/bin, the home path becomes @HOME@ (filled in per user)
grep -rlI "$H/.local/bin/" "$S/home" | xargs -r sed -i "s#$H/.local/bin/#/usr/local/bin/#g"
sed -i "s#^exec_once=~/.local/bin/dock-autohide#exec_once=/usr/local/bin/dock-autohide#" "$S/home/.config/mango/config.conf"
grep -q shell-firstlogin "$S/home/.config/mango/config.conf" ||
    printf '\n# first login of a new user: dconf settings (fonts, theme, Celluloid)\nexec_once=/usr/local/bin/shell-firstlogin\n' >> "$S/home/.config/mango/config.conf"
grep -rlI "$H" "$S/home" | xargs -r sed -i "s#$H#@HOME@#g"
# the username in comments (e.g. "<you>:greeter") -> a placeholder
grep -rlI "$(id -un):" "$S/home" | xargs -r sed -i "s#$(id -un):greeter#<user>:greeter#g"

# ---------- system files -> setup/root ----------
sys_items=(
    /usr/local/share/shell-greeter
    /etc/greetd/config.toml
    /etc/brave/policies/managed
    /etc/udev/rules.d/90-battery-threshold.rules
    /etc/tuned/profiles/laptop-battery /etc/tuned/ppd.conf
    /etc/dnf/dnf.conf
    "/etc/yum.repos.d/_copr:copr.fedorainfracloud.org:errornointernet:quickshell.repo"
    /etc/yum.repos.d/brave-browser.repo /etc/yum.repos.d/librewolf.repo
)
for p in "${sys_items[@]}"; do
    mkdir -p "$S/root$(dirname "$p")"
    cp -a "$p" "$S/root$p"
done
mkdir -p "$S/root/usr/local/bin"
cp -a "$H"/.local/bin/{shot,dock-autohide,dock-pin,mango-cycle} src/shell-user-setup src/shell-firstlogin "$S/root/usr/local/bin/"
chmod 755 "$S/root/usr/local/bin/"*

# the login screen's account: created by sysusers.d/tmpfiles.d (no Fedora package provides it)
install -Dm644 src/system/shell-greeter.sysusers "$S/root/usr/lib/sysusers.d/shell-greeter.conf"
install -Dm644 src/system/shell-greeter.tmpfiles "$S/root/usr/lib/tmpfiles.d/shell-greeter.conf"

# LibreWolf tweaks: profile user.js -> defaults for every new profile
lw=$(ls -d "$H"/.config/librewolf/librewolf/*.default-release | head -1)
mkdir -p "$S/root/usr/share/librewolf/defaults/pref"
sed 's/^user_pref(/pref(/' "$lw/user.js" > "$S/root/usr/share/librewolf/defaults/pref/zz-shell.js"

# login screen theme colors (the wallpaper copy goes to private/)
cp /var/cache/shell-greeter/colors.json "$S/greeter-cache/"

# ---------- wallpapers -> private/ (not committed) ----------
cp -a "$H"/.local/share/wallpapers/. "$P/home/.local/share/wallpapers/"
cp /var/cache/shell-greeter/wallpaper "$P/greeter-cache/"

# ---------- packages ----------
rpm -qa --qf '%{NAME}\n' | grep -vE '^(gpg-pubkey|libreoffice)' | sort -u > "$S/packages.txt"
# every name must be installable from the repos the installer uses
avail=$(mktemp)
dnf repoquery -q --available --qf '%{name}\n' $(cat "$S/packages.txt") 2>/dev/null | sort -u > "$avail"
missing=$(comm -23 "$S/packages.txt" "$avail")
if [ -n "$missing" ]; then
    echo "Not available in any repo (left out):"; echo "$missing" | sed 's/^/  /'
    comm -12 "$S/packages.txt" "$avail" > "$S/packages.tmp" && mv "$S/packages.tmp" "$S/packages.txt"
fi
rm -f "$avail"
# the installer must also be able to reach the network on any machine
for p in NetworkManager NetworkManager-wifi NetworkManager-config-connectivity-fedora wpa_supplicant iwlwifi-mvm-firmware policycoreutils-python-utils; do
    grep -qx "$p" "$S/packages.txt" || echo "$p" >> "$S/packages.txt"
done
sort -u -o "$S/packages.txt" "$S/packages.txt"

# ---------- secret check ----------
if grep -rIlE 'BEGIN (OPENSSH|RSA|EC) PRIVATE|psk=|password=|Login Data|cookies.sqlite|gh[pousr]_[A-Za-z0-9]{20,}' "$S"; then
    echo "!! possible secrets above, stopping" >&2; exit 1
fi

echo "snapshot updated: $(wc -l < "$S/packages.txt") packages; review with git diff"
