#!/bin/bash
# Turn a fresh Fedora Everything install with no desktop (Minimal Install) into the Vayu Linux desktop:
#   curl -fsSL https://raw.githubusercontent.com/mbodigi/fedora-mangowm-remix/main/get.sh | bash
# Downloads this repo (REF=<branch or tag> to pick a version) and runs install.sh, which asks for
# your password once (sudo). Read install.sh first if you like: it's short.
set -euo pipefail

REPO=mbodigi/fedora-mangowm-remix
REF=${REF:-main}

[ "$(id -u)" != 0 ] || { echo "Run this as your normal user, not root: it uses sudo itself." >&2; exit 1; }
. /etc/os-release
# any stable Fedora release from 44 on (no beta, no Rawhide)
[ "${ID:-}" = fedora ] && [ "${RELEASE_TYPE:-}" = stable ] && [ "${VERSION_ID:-0}" -ge 44 ] 2>/dev/null ||
    { echo "This setup needs a stable Fedora release, 44 or newer (found: ${PRETTY_NAME:-unknown})." >&2; exit 1; }

# a Minimal Fedora has no tar; it's needed to unpack the download (asks for your password)
if ! command -v tar >/dev/null; then
    echo "Installing tar (needed to unpack the download)…"
    sudo dnf -y install tar < /dev/tty
fi

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
echo "Downloading $REPO ($REF)…"
curl -fsSL "https://github.com/$REPO/archive/$REF.tar.gz" | tar -xz -C "$dir" --strip-components=1

# the installer reads from the terminal (sudo), not from this piped script
"$dir/install.sh" < /dev/tty
