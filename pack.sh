#!/bin/bash
# Turn setup/ (plus private/ wallpapers, if this machine has them) into build/:
#   build/shell-setup.ks       the kickstart, with setup/packages.txt filled in
#   build/shell-bundle.tar.gz  what goes on the ISO (root/, home/, greeter-cache/)
# Works from a fresh clone: without private/ the install simply has no wallpaper yet.
# PUBLIC=1 leaves private/ out even when it's here (for ISOs that get published).
# OFFLINE=1 makes the kickstart install from the package repo on the ISO.
set -euo pipefail
cd "$(dirname "$0")"
[ -f setup/packages.txt ] || { echo "setup/ is missing: run ./collect.sh on the source machine"; exit 1; }

rm -rf build/bundle build/shell-bundle.tar.gz build/shell-setup.ks
mkdir -p build/bundle
cp -a setup/root setup/home setup/greeter-cache build/bundle/
[ -d private ] && [ "${PUBLIC:-0}" != 1 ] && cp -a private/. build/bundle/

# OFFLINE=1: packages from the repo on the ISO; otherwise they download during the install
repos=src/repos-online.ks
[ "${OFFLINE:-0}" = 1 ] && repos=src/repos-offline.ks
awk -v list=setup/packages.txt -v repos="$repos" '
    /^@PACKAGES@$/ { while ((getline l < list) > 0) print l; next }
    /^@REPOS@$/    { while ((getline l < repos) > 0) print l; next }
    { print }' src/shell-setup.ks.in > build/shell-setup.ks
tar -czf build/shell-bundle.tar.gz -C build/bundle root home greeter-cache

echo "packages: $(wc -l < setup/packages.txt)"
echo "bundle:   $(du -sh build/shell-bundle.tar.gz | cut -f1)$( [ -d private ] && [ "${PUBLIC:-0}" != 1 ] || echo ' (no wallpapers)')"
