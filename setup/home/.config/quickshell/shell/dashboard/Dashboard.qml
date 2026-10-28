// Dashboard (Super+D): Overview, Wallpapers.
// Toggle with: qs -c shell ipc call dashboard toggle   (or openTab overview|wallpapers|wallhaven)
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../services"
import "../bar"

PanelWindow {
    id: root

    property bool open: false
    property string tab: "overview"
    property string wallSource: "mine"

    visible: open
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Normal
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    WlrLayershell.namespace: "shell-dashboard"

    onOpenChanged: if (open) { Panels.control = false; Notifs.centerOpen = false; }

    IpcHandler {
        target: "dashboard"
        function toggle(): void { root.open = !root.open; }
        function openTab(tab: string): void {
            root.wallSource = tab === "wallhaven" ? "wallhaven" : "mine";
            root.tab = tab === "wallhaven" ? "wallpapers" : tab;
            root.open = true;
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.open = false
    }

    Rectangle {
        id: panel
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 6
        width: 1000
        height: 640
        radius: 24
        color: Theme.surfaceContainer
        focus: true
        Keys.onEscapePressed: root.open = false

        MouseArea { anchors.fill: parent }   // swallow clicks inside

        Row {
            id: tabs
            anchors { top: parent.top; horizontalCenter: parent.horizontalCenter; topMargin: 14 }
            spacing: 8

            Repeater {
                model: [
                    { id: "overview", icon: "dashboard", label: "Overview" },
                    { id: "wallpapers", icon: "wallpaper", label: "Wallpapers" }
                ]

                Chip {
                    required property var modelData
                    highlighted: root.tab === modelData.id
                    implicitHeight: 34
                    onClicked: root.tab = modelData.id
                    Icon {
                        name: modelData.icon
                        color: root.tab === modelData.id ? Theme.textOnPrimary : Theme.text
                    }
                    Label {
                        text: modelData.label
                        color: root.tab === modelData.id ? Theme.textOnPrimary : Theme.text
                    }
                }
            }
        }

        Loader {
            anchors { left: parent.left; right: parent.right; top: tabs.bottom; bottom: parent.bottom; margins: 16 }
            active: root.open
            sourceComponent: root.tab === "wallpapers" ? wallpapers : overview
        }

        Component { id: overview; Overview {} }
        Component { id: wallpapers; Wallpapers { source: root.wallSource } }
    }
}
