// Top bar: tags + window title on the left; media, tray, coffee, stats (CPU, RAM, network), battery, clock on the right.
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services"

PanelWindow {
    id: bar

    required property var modelData
    screen: modelData

    anchors { top: true; left: true; right: true }
    readonly property bool mac: Settings.get("barStyle") === "mac"

    implicitHeight: mac ? 28 : 36
    color: mac ? Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.7) : Theme.surface

    // faint gray line along the bottom of the flat bar
    Rectangle {
        visible: bar.mac
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 1
        color: Qt.rgba(1, 1, 1, 0.08)
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 6

        Workspaces { flat: bar.mac }

        Label {
            Layout.fillWidth: true
            Layout.leftMargin: 6
            text: Mango.focusedTitle
            color: Theme.textMuted
        }

        NowPlaying { flat: bar.mac }

        Tray { flat: bar.mac }

        Coffee { barWindow: bar; flat: bar.mac }

        Chip {
            flat: bar.mac
            visible: Settings.get("showCpu")
            Icon { name: "memory" }
            Label { text: Math.round(SysStats.cpu) + "%" }
        }

        Chip {
            flat: bar.mac
            visible: Settings.get("showRam")
            Icon { name: "memory_alt" }
            Label { text: SysStats.memUsedGiB.toFixed(1) + "G" }
        }

        Chip {
            flat: bar.mac
            visible: Settings.get("showNet")
            Icon { name: "swap_vert" }
            Label { text: "↓" + SysStats.mbps(SysStats.rxRate) + " ↑" + SysStats.mbps(SysStats.txRate) + " Mbps" }
        }

        NotifButton { flat: bar.mac }

        Battery { flat: bar.mac }

        ControlButton { flat: bar.mac }

        Chip {
            flat: bar.mac
            Label {
                text: Qt.formatDateTime(clock.date, Settings.get("clock24h") ? "ddd MMM d   HH:mm" : "ddd MMM d   h:mm AP")
                font.weight: Font.DemiBold
            }
        }
    }
}
