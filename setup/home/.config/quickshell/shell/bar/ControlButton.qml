// Status icons (Wi-Fi, Bluetooth, volume) that open the control center.
import QtQuick
import Quickshell.Bluetooth
import "../services"

Chip {
    id: root

    readonly property bool open: Panels.control

    highlighted: open
    onClicked: Panels.control = !Panels.control
    onWheel: event => Audio.step(event.angleDelta.y > 0 ? 0.05 : -0.05)

    Icon { name: Net.icon(); color: root.fg }
    Icon {
        visible: Bluetooth.defaultAdapter !== null && Bluetooth.defaultAdapter.enabled
        name: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.devices.values.some(d => d.connected) ? "bluetooth_connected" : "bluetooth"
        color: root.fg
    }
    Icon {
        name: Audio.muted ? "volume_off" : Audio.volume < 0.34 ? "volume_mute" : Audio.volume < 0.67 ? "volume_down" : "volume_up"
        color: root.fg
    }
}
