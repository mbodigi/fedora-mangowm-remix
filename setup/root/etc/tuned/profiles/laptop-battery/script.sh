#!/bin/sh
# Runtime power management for PCI devices and the deepest PCIe link power state
case "$1" in
start)
    echo powersupersave > /sys/module/pcie_aspm/parameters/policy 2>/dev/null
    for d in /sys/bus/pci/devices/*/power/control; do echo auto > "$d"; done
    ;;
stop)
    echo default > /sys/module/pcie_aspm/parameters/policy 2>/dev/null
    for d in /sys/bus/pci/devices/*/power/control; do echo on > "$d"; done
    ;;
esac
exit 0
