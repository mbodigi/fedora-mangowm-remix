#!/bin/bash
# Build the offline install ISO: Fedora's official netinst ISO (for its installer) + our kickstart,
# the setup bundle, and every package in an on-ISO repo (/shellrepo), so installing needs no internet.
# Builds from setup/ (via ./pack.sh). Uses a rootless podman container for the tools (lorax/mkksiso,
# pykickstart), so nothing is installed on this machine.
#   ./build-iso.sh            ->  out/Fedora-Shell-44-offline.iso         (with your wallpapers, for yourself)
#   PUBLIC=1 ./build-iso.sh   ->  out/Shell-Setup-44-Remix-offline.iso    (repo contents only, safe to publish)
set -euo pipefail
cd "$(dirname "$0")"

REL=44
BASE=https://dl.fedoraproject.org/pub/fedora/linux/releases/$REL/Everything/x86_64/iso
ISO=Fedora-Everything-netinst-x86_64-44-1.7.iso
SUM=Fedora-Everything-44-1.7-x86_64-CHECKSUM
LABEL=Fedora-E-dvd-x86_64-44   # the ISO's volume label (mkksiso keeps it); the installer finds /shellrepo by it
OUT_ISO=Fedora-Shell-44-offline.iso
[ "${PUBLIC:-0}" = 1 ] && OUT_ISO=Shell-Setup-44-Remix-offline.iso

./pack.sh
mkdir -p download out

# official ISO, checked against Fedora's signed checksum file
if [ ! -f "download/$ISO" ]; then
    curl -fL --progress-bar -C - -o "download/$ISO.part" "$BASE/$ISO"
    mv "download/$ISO.part" "download/$ISO"
fi
curl -fsSL -o "download/$SUM" "$BASE/$SUM"
curl -fsSL -o download/fedora.gpg https://fedoraproject.org/fedora.gpg
gpgv --keyring download/fedora.gpg "download/$SUM"
(cd download && sha256sum --ignore-missing -c "$SUM")

# tools image, built once (rootless)
TOOLS=localhost/iso-tools:$REL
if ! podman image exists $TOOLS; then
    podman rm -f iso-tools-build >/dev/null 2>&1 || true
    podman run --name iso-tools-build registry.fedoraproject.org/fedora:$REL dnf -y -q install lorax pykickstart xorriso
    podman commit -q iso-tools-build $TOOLS >/dev/null
    podman rm iso-tools-build >/dev/null
fi

# every package, with dependencies, into build/shellrepo (rootless container, ~2.5 GB the first time)
podman run --rm --security-opt label=disable -v "$PWD:/work" registry.fedoraproject.org/fedora:$REL bash /work/src/make-repo.sh

# validate a copy with the %pre-generated bootloader line filled in (that file only exists in the installer)
sed "s|^%include /tmp/bootloader.ks|bootloader --sdboot|" build/shell-setup.ks > build/validate.ks
podman run --rm --security-opt label=disable -v "$PWD:/work" -w /work $TOOLS ksvalidator -v F$REL build/validate.ks

# mkksiso rebuilds the UEFI boot image (it has its own copy of the boot menu) on a loop device,
# which only root can attach: run this one step in a privileged root container (password dialog)
rm -f "out/$OUT_ISO"; mkdir -p build/tmp
podman save -q $TOOLS | pkexec sh -euc "
    podman load -q >/dev/null
    podman run --rm --privileged -v /dev:/dev -v '$PWD:/work' -w /work $TOOLS \
        mkksiso --tmp /work/build/tmp --ks build/shell-setup.ks --add build/shell-bundle.tar.gz --add build/shellrepo \
            -c 'inst.repo=hd:LABEL=$LABEL:/shellrepo' download/$ISO out/$OUT_ISO
    chown -R $(id -u):$(id -g) '$PWD/out' '$PWD/build/tmp'
"
ls -lh "out/$OUT_ISO"
