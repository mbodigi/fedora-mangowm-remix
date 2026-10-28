pragma Singleton
// Low battery warnings: a notification at 15% and an urgent one at 5% while discharging.
import QtQuick
import Quickshell
import Quickshell.Services.UPower

Singleton {
    id: root

    readonly property var dev: UPower.displayDevice
    readonly property real pct: dev ? (dev.percentage <= 1 ? dev.percentage * 100 : dev.percentage) : 100
    readonly property bool discharging: dev && dev.state === UPowerDeviceState.Discharging
    property int warned: 100   // lowest threshold already warned about this discharge

    function notify(urgency, title, body) {
        Quickshell.execDetached(["notify-send", "-a", "Battery", "-u", urgency, "-i", "battery-caution", title, body]);
    }

    onDischargingChanged: if (!discharging) warned = 100
    onPctChanged: {
        if (!discharging) return;
        if (pct <= 5 && warned > 5) {
            warned = 5;
            notify("critical", "Battery critically low", Math.round(pct) + "% left — plug in now");
        } else if (pct <= 15 && warned > 15) {
            warned = 15;
            notify("normal", "Battery low", Math.round(pct) + "% left");
        }
    }
}
