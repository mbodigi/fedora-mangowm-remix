// Coffee toggle: while on, the screen never dims, locks or sleeps from idle.
import QtQuick
import Quickshell.Wayland
import "../services"

Chip {
    id: root

    required property var barWindow
    readonly property bool awake: Idle.coffee

    highlighted: awake
    onClicked: Idle.coffee = !Idle.coffee

    IdleInhibitor {
        window: root.barWindow
        enabled: root.awake
    }

    Icon {
        name: "coffee"
        filled: root.awake
        color: root.fg
    }
}
