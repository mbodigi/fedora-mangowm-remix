#!/bin/bash
# Test the ISO in a UEFI VM (libvirt user session, shows up in virt-manager as "QEMU/KVM User session").
# Uses the real kickstart plus answers for the installer screens, so the install runs by itself:
#   test user "test" / password "test", 30 GB virtual disk, wiped.
#   ./test-vm.sh try       boot the ISO to the installer (installs nothing)
#   ./test-vm.sh screenshot
#   ./test-vm.sh install   install from out/Fedora-Shell-44-offline.iso, with no network (VM powers off when done)
#   ./test-vm.sh boot      boot the installed VM
#   ./test-vm.sh delete    remove the VM and its disk
set -euo pipefail
cd "$(dirname "$0")"
NAME=shell-test
C=qemu:///session
ISO=${ISO:-$PWD/out/Fedora-Shell-44-offline.iso}
MEM=${MEM:-3072}
# no network by default: proves the install is offline (NET='--network user' to give it one)
NET=${NET:---network none}
T=$PWD/test
mkdir -p "$T"

case "${1:-}" in
try)
    # boot the ISO exactly like a USB stick (its own boot menu + kickstart), no answers: the installer
    # stops at its summary screen and nothing is installed
    [ -f "$ISO" ] || { echo "build the ISO first"; exit 1; }
    virt-install --connect $C --name $NAME --osinfo fedora-unknown \
        --memory $MEM --vcpus 2 \
        --boot uefi,firmware.feature0.name=secure-boot,firmware.feature0.enabled=no \
        --disk size=30,format=qcow2 \
        --cdrom "$ISO" \
        --network user --graphics spice --video virtio \
        --noautoconsole
    ;;
screenshot)
    virsh -c $C screenshot $NAME "$T/screen.ppm" >/dev/null
    echo "$T/screen.ppm"
    ;;
install)
    [ -f "$ISO" ] || { echo "build the ISO first"; exit 1; }
    {
        sed -n '1,/^graphical$/p' build/shell-setup.ks
        cat <<'EOF'
# --- test answers (only in the test VM) ---
lang en_US.UTF-8
keyboard us
timezone America/Los_Angeles --utc
zerombr
clearpart --all --initlabel
autopart
rootpw --lock
user --name=test --password=test --plaintext --groups=wheel
poweroff
EOF
        sed '1,/^graphical$/d' build/shell-setup.ks
    } > "$T/test.ks"
    rm -f "$T/serial.log"
    virt-install --connect $C --name $NAME --osinfo fedora-unknown \
        --memory $MEM --vcpus 2 \
        --boot uefi,firmware.feature0.name=secure-boot,firmware.feature0.enabled=no \
        --disk size=30,format=qcow2 \
        --location "$ISO" --initrd-inject "$T/test.ks" \
        --extra-args "inst.ks=file:/test.ks inst.stage2=hd:LABEL=Fedora-E-dvd-x86_64-44 inst.repo=hd:LABEL=Fedora-E-dvd-x86_64-44:/shellrepo console=tty0 console=ttyS0,115200" \
        $NET --graphics spice --video virtio \
        --serial file,path="$T/serial.log" \
        --noautoconsole --noreboot
    ;;
boot)
    virsh -c $C start $NAME
    ;;
delete)
    virsh -c $C destroy $NAME 2>/dev/null || true
    virsh -c $C undefine $NAME --nvram --remove-all-storage
    ;;
*)
    sed -n "2,10p" "$0"; exit 1 ;;
esac
