# Checklist before pushing setup changes

## 1. Snapshot

- [ ] `./collect.sh`, then `git diff`: look over what changed
- [ ] Nothing personal in the diff: no username, passwords, tokens, keys, NextDNS ID, wallpapers

## 2. Install test (on a fresh Fedora 44 VM, not this machine)

- [ ] Push to a branch, then in the VM: `curl -fsSL https://raw.githubusercontent.com/mbodigi/fedora-mangowm-remix/<branch>/get.sh | REF=<branch> bash`
- [ ] It finishes without errors and doesn't remove packages (Fedora's GRUB and grubby stay)
- [ ] Reboot: the greeter appears → log in to Mango → the bar and dock come up, on workspace 1

## 3. Dock

- [ ] Hidden while a window covers its strip; shown at the left edge; stays up while hovering it
- [ ] Right click → **Pin to dock** / **Unpin**, then move away: the dock **hides again**
- [ ] Click a running app: it comes forward; again: it minimizes; again: restored
- [ ] `Super + Shift + P` pins / unpins the focused app

## 4. Control center

- [ ] Speaker icon on the volume slider opens the output/input drop-down; right click mutes
- [ ] Bluetooth list: a device connects and stays connected while the list is open
