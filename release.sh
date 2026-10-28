#!/bin/bash
# Prepare the public ISO (from PUBLIC=1 ./build-iso.sh) for a GitHub release, all named after VERSION:
#   out/release/fedora-mangowm-remix-VERSION-x86_64.iso            (net-install: one file, under 2 GB)
#     or .iso.part1..N                                               (offline, OFFLINE=1: split for GitHub)
#   out/release/fedora-mangowm-remix-VERSION-x86_64.iso.sha256     (of the joined ISO)
# The release tag is fedora-mangowm-remix-VERSION.
set -euo pipefail
cd "$(dirname "$0")"
VERSION=$(cat VERSION)
TAG=fedora-mangowm-remix-$VERSION
NAME=$TAG-x86_64
[ "${OFFLINE:-0}" = 1 ] && NAME=$NAME-offline
ISO=out/$NAME.iso
[ -f "$ISO" ] || { echo "no $ISO: run PUBLIC=1 ./build-iso.sh first"; exit 1; }

rm -rf out/release; mkdir -p out/release
(cd out && sha256sum "$NAME.iso") > "out/release/$NAME.iso.sha256"

# GitHub takes files up to 2 GiB: a net-install ISO goes up as is, an offline one in parts
if [ "$(stat -c %s "$ISO")" -lt 2000000000 ]; then
    ln -f "$ISO" "out/release/$NAME.iso"
    files=(out/release/$NAME.iso)
else
    split -b 1900M --numeric-suffixes=1 -a 1 "$ISO" "out/release/$NAME.iso.part"
    # the parts must join back to exactly the ISO
    joined=$(cat out/release/$NAME.iso.part* | sha256sum | cut -d' ' -f1)
    [ "$joined" = "$(cut -d' ' -f1 out/release/$NAME.iso.sha256)" ] || { echo "parts don't join back to the ISO" >&2; exit 1; }
    files=(out/release/$NAME.iso.part*)
fi


ls -l out/release
