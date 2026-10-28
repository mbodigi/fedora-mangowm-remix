import QtQuick
import Quickshell.Services.UPower
import "../services"

Chip {
    id: root

    readonly property var dev: UPower.displayDevice
    readonly property real pct: dev ? (dev.percentage <= 1 ? dev.percentage * 100 : dev.percentage) : 0
    readonly property bool charging: dev && (dev.state === UPowerDeviceState.Charging || dev.state === UPowerDeviceState.PendingCharge)
    readonly property bool full: dev && dev.state === UPowerDeviceState.FullyCharged

    visible: dev && dev.isLaptopBattery

    Icon {
        name: root.charging ? "battery_charging_full"
            : root.pct > 90 ? "battery_full"
            : root.pct > 75 ? "battery_6_bar"
            : root.pct > 60 ? "battery_5_bar"
            : root.pct > 45 ? "battery_4_bar"
            : root.pct > 30 ? "battery_3_bar"
            : root.pct > 15 ? "battery_2_bar"
            : "battery_alert"
        color: !root.charging && root.pct <= 15 ? Theme.error : Theme.text
    }
    Label { text: Math.round(root.pct) + "%" }
}
