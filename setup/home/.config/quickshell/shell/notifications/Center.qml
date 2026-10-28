// Notification history panel (opened from the bell on the bar).
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services"
import "../bar"

PanelWindow {
    id: root

    visible: Notifs.centerOpen
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Normal
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    WlrLayershell.namespace: "shell-notification-center"
    onVisibleChanged: if (visible) Panels.control = false

    MouseArea {
        anchors.fill: parent
        onClicked: Notifs.centerOpen = false
    }

    Rectangle {
        id: panel
        anchors { top: parent.top; right: parent.right; topMargin: 6; rightMargin: 8 }
        width: 404
        height: Math.min(parent.height - 20, Math.max(120, header.height + list.contentHeight + 36))
        radius: 18
        color: Theme.surfaceContainer
        focus: true
        Keys.onEscapePressed: Notifs.centerOpen = false

        MouseArea { anchors.fill: parent }   // swallow clicks inside

        Row {
            id: header
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
            height: 30
            spacing: 6

            Label {
                width: parent.width - dnd.width - clear.width - 12
                height: parent.height
                text: Notifs.count > 0 ? "Notifications (" + Notifs.count + ")" : "Notifications"
                font.pixelSize: 15
                font.weight: Font.DemiBold
            }
            Chip {
                id: dnd
                highlighted: Notifs.dnd
                onClicked: Notifs.dnd = !Notifs.dnd
                Icon {
                    name: Notifs.dnd ? "notifications_off" : "notifications_active"
                    color: Notifs.dnd ? Theme.textOnPrimary : Theme.text
                }
                Label {
                    text: "Do not disturb"
                    color: Notifs.dnd ? Theme.textOnPrimary : Theme.text
                }
            }
            Chip {
                id: clear
                visible: Notifs.count > 0
                onClicked: Notifs.clearAll()
                Icon { name: "clear_all" }
            }
        }

        ListView {
            id: list
            anchors { left: parent.left; right: parent.right; top: header.bottom; bottom: parent.bottom; margins: 12 }
            spacing: 8
            clip: true
            model: [...Notifs.history].reverse()

            delegate: NotifCard {
                required property var modelData
                notif: modelData
            }
        }

        Label {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 16
            visible: Notifs.count === 0
            text: "No notifications"
            color: Theme.outline
        }
    }
}
