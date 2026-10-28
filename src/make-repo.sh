#!/bin/bash
# Runs inside a fedora container (from build-iso.sh) with the repo mounted at /work.
# Downloads every package of setup/packages.txt plus src/offline-extra-packages.txt, with all their
# dependencies, from the same repos the installed system uses, and makes build/shellrepo/ a repo
# (with Fedora's package groups, which the installer's base group needs).
set -euo pipefail
cd /work
R=44

# the same repos as the installed system: RPM Fusion and terra from their release packages,
# the rest from the .repo files in setup/
dnf -y -q install \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$R.noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$R.noarch.rpm" >/dev/null
dnf -y -q install --nogpgcheck --repofrompath "terra,https://repos.fyralabs.com/terra$R" terra-release >/dev/null
cp setup/root/etc/yum.repos.d/*.repo /etc/yum.repos.d/
dnf -y -q install createrepo_c zstd dnf5-plugins >/dev/null
dnf -y -q makecache >/dev/null

# downloads are kept in download/rpms between builds; only new or updated packages are fetched
mkdir -p download/rpms
pkgs=$(grep -vh '^#' setup/packages.txt src/offline-extra-packages.txt | sort -u)
dnf download -q --setopt=max_parallel_downloads=15 --resolve --alldeps --skip-unavailable --arch x86_64 --arch noarch --destdir download/rpms $pkgs

# newest version of each package only (older ones pile up in the cache across builds)
rm -rf build/shellrepo; mkdir -p build/shellrepo/Packages
ln download/rpms/*.rpm build/shellrepo/Packages/ 2>/dev/null || cp download/rpms/*.rpm build/shellrepo/Packages/
createrepo_c -q --update build/shellrepo >/dev/null
dnf repomanage -q --old build/shellrepo | xargs -r rm -f

comps=$(ls -t /var/cache/libdnf5/updates-*/repodata/*comps-Everything*.xml.* | head -1)
zstd -dqf "$comps" -o build/comps.xml
createrepo_c -q -g /work/build/comps.xml build/shellrepo >/dev/null
echo "offline repo: $(ls build/shellrepo/Packages | wc -l) packages, $(du -sh build/shellrepo | cut -f1)"
