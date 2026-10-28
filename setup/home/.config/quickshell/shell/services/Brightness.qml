pragma Singleton
// Laptop screen backlight: read from sysfs, set through logind (no root needed).
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string device: "intel_backlight"
    property int max: 1
    property int current: 0
    readonly property real level: max > 0 ? current / max : 0

    signal changed()

    function set(value) {
        current = Math.round(Math.max(0.01, Math.min(1, value)) * max);
        Quickshell.execDetached(["busctl", "call", "org.freedesktop.login1",
            "/org/freedesktop/login1/session/auto", "org.freedesktop.login1.Session",
            "SetBrightness", "ssu", "backlight", device, String(current)]);
    }

    function refresh() {
        curFile.reload();   // pick up changes made elsewhere (blockLoading makes this synchronous)
        current = Number(curFile.text());
    }

    function step(delta) {
        refresh();
        set(Math.round((level + delta) * 100) / 100);
        changed();
    }

    FileView {
        id: maxFile
        path: "/sys/class/backlight/" + root.device + "/max_brightness"
        onLoaded: root.max = Number(maxFile.text()) || 1
    }

    FileView {
        id: curFile
        blockLoading: true
        path: "/sys/class/backlight/" + root.device + "/brightness"
        onLoaded: root.current = Number(curFile.text())
    }
}
