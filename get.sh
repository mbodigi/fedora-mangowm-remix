#!/bin/bash
# Turn a fresh Fedora 44 install into the Fedora MangoWM Remix desktop:
#   curl -fsSL https://raw.githubusercontent.com/mbodigi/fedora-mangowm-remix/main/get.sh | bash
# Downloads this repo (REF=<branch or tag> to pick a version) and runs install.sh, which asks for
# your password once (sudo). Read install.sh first if you like: it's short.
set -euo pipefail

REPO=mbodigi/fedora-mangowm-remix
REF=${REF:-main}

[ "$(id -u)" != 0 ] || { echo "Run this as your normal user, not root: it uses sudo itself." >&2; exit 1; }
. /etc/os-release
[ "${ID:-}" = fedora ] && [ "${VERSION_ID:-}" = 44 ] || { echo "This setup is for Fedora 44 (found: ${PRETTY_NAME:-unknown})." >&2; exit 1; }

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
