# Release checklist

Run through this for every release, on the **final** build (not an earlier one).

## 1. Build

- [ ] Bump `VERSION` (Fedora release . build number, e.g. `44.2`)
- [ ] `./collect.sh` on the source machine, then `git diff` and look over what changed
- [ ] `./build-iso.sh` (personal) and `PUBLIC=1 ./build-iso.sh` (public)

## 2. Public ISO contents

- [ ] No wallpapers in the bundle (`private/` left out) and no username, passwords, tokens or NextDNS ID:
  extract `shell-bundle.tar.gz` and `shell-setup.ks` from the ISO and grep them
- [ ] All boot menus (BIOS, ISO EFI, the hidden UEFI image) have `inst.ks=…` and `inst.repo=…:/shellrepo`

## 3. Install test (VM, no network)

`ISO=$PWD/out/fedora-mangowm-remix-$(cat VERSION)-x86_64.iso ./test-vm.sh install`

- [ ] The installer goes straight through (no warning on the summary screen) and the VM powers off by itself
- [ ] No error in "Running post-installation scripts" (`/root/shell-setup-post.log` on the installed system)
- [ ] `./test-vm.sh boot`: systemd-boot → the login screen → log in as `test` / `test` → the bar comes up
- [ ] Lands on workspace 1

## 4. Dock (on the source machine or the installed VM)

- [ ] Hidden while a window covers its strip; shown at the left edge; stays up while hovering it
- [ ] Hides again about half a second after the pointer leaves
- [ ] Click a running app: it comes forward; click it again: it minimizes; click again: it's restored
- [ ] Middle click closes the app
- [ ] Right click → **Pin to dock**, then move away: the dock **hides again**
- [ ] Right click → **Unpin from dock**, then move away: the dock **hides again**
- [ ] A pinned app that isn't running stays in the dock and opens on click
- [ ] `Super + Shift + P` pins / unpins the focused app (with a notification)
- [ ] Fullscreen window: the dock stays hidden even at the left edge
- [ ] Open and close apps while the dock is shown: icons update, no stuck state

## 5. Release

- [ ] `./release.sh` (parts, checksum, torrent; it checks the parts join back to the ISO)
- [ ] Commit and push; release notes in `out/release/notes.md`
- [ ] `gh release create fedora-mangowm-remix-VERSION …` with the parts, `.sha256` and `.torrent`
- [ ] Check as a visitor: files download, sizes match, the torrent's web seed serves a piece that matches
