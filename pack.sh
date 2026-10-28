#!/bin/bash
# Turn setup/ (plus private/ wallpapers, if this machine has them) into build/:
#   build/shell-setup.ks       the kickstart, with setup/packages.txt filled in
#   build/shell-bundle.tar.gz  what goes on the ISO (root/, home/, greeter-cache/)
# Works from a fresh clone: without private/ the install simply has no wallpaper yet.
set -euo pipefail
cd "$(dirname "$0")"
[ -f setup/packages.txt ] || { echo "setup/ is missing: run ./collect.sh on the source machine"; exit 1; }

rm -rf build/bundle build/shell-bundle.tar.gz build/shell-setup.ks
mkdir -p build/bundle
cp -a setup/root setup/home setup/greeter-cache build/bundle/
[ -d private ] && cp -a private/. build/bundle/

awk -v list=setup/packages.txt '/^@PACKAGES@$/ { while ((getline l < list) > 0) print l; next } { print }' \
    src/shell-setup.ks.in > build/shell-setup.ks
tar -czf build/shell-bundle.tar.gz -C build/bundle root home greeter-cache

echo "packages: $(wc -l < setup/packages.txt)"
echo "bundle:   $(du -sh build/shell-bundle.tar.gz | cut -f1)$([ -d private ] || echo ' (no wallpapers: private/ not present)')"
