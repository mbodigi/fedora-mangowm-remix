#!/bin/bash
# Prepare the public ISO (from PUBLIC=1 ./build-iso.sh) for a GitHub release, all named after VERSION:
#   out/release/fedora-mangowm-remix-VERSION-x86_64.iso.part1..N   (under GitHub's 2 GB per file)
#   out/release/fedora-mangowm-remix-VERSION-x86_64.iso.sha256     (of the joined ISO)
#   out/release/fedora-mangowm-remix-VERSION-x86_64.torrent        (folder fedora-mangowm-remix-VERSION,
#                                                                    with the release as its web seed)
# The release tag must be fedora-mangowm-remix-VERSION: the torrent's web seed and folder use it.
set -euo pipefail
cd "$(dirname "$0")"
VERSION=$(cat VERSION)
TAG=fedora-mangowm-remix-$VERSION
NAME=$TAG-x86_64
ISO=out/$NAME.iso
[ -f "$ISO" ] || { echo "no $ISO: run PUBLIC=1 ./build-iso.sh first"; exit 1; }

rm -rf out/release; mkdir -p out/release
(cd out && sha256sum "$NAME.iso") > "out/release/$NAME.iso.sha256"
split -b 1900M --numeric-suffixes=1 -a 1 "$ISO" "out/release/$NAME.iso.part"

# the parts must join back to exactly the ISO
joined=$(cat out/release/$NAME.iso.part* | sha256sum | cut -d' ' -f1)
[ "$joined" = "$(cut -d' ' -f1 out/release/$NAME.iso.sha256)" ] || { echo "parts don't join back to the ISO" >&2; exit 1; }

src/make-torrent.py "$TAG" out/release/$NAME.iso.part* "out/release/$NAME.iso.sha256" > out/release/torrent-info.txt
mv "out/release/$TAG.torrent" "out/release/$NAME.torrent"

ls -l out/release
echo "magnet: $(sed -n 2p out/release/torrent-info.txt)"
