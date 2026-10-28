// One notification: icon/image, app name, summary, body, action buttons. Click = default action (or dismiss).
import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import "../services"
import "../bar"

Rectangle {
    id: card

    required property var notif
    property bool popup: false     // popups auto-hide; history cards don't

    signal hidden()

    width: 380
    height: content.implicitHeight + 24
    radius: 16
    color: Theme.surface
    border.width: 1
    border.color: notif.urgency === NotificationUrgency.Critical ? Theme.error : Theme.surfaceHigh

    Timer {
        running: card.popup && card.notif.urgency !== NotificationUrgency.Critical && !hover.containsMouse
        interval: card.notif.expireTimeout > 0 ? card.notif.expireTimeout * 1000 : 6000
        onTriggered: card.hidden()
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            const def = card.notif.actions.find(a => a.identifier === "default");
            if (mouse.button === Qt.LeftButton && def)
                def.invoke();
            else
                card.notif.dismiss();
        }
    }

    Row {
        id: content
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
        spacing: 12

        IconImage {
            id: icon
            implicitSize: 40
            visible: source != ""
            source: card.notif.image || (card.notif.appIcon ? Quickshell.iconPath(card.notif.appIcon, true) : "")
        }

        Column {
            width: parent.width - (icon.visible ? icon.width + parent.spacing : 0) - 24
            spacing: 3

            Label {
                width: parent.width
                text: card.notif.appName
                color: Theme.textMuted
                font.pixelSize: 11
            }
            Label {
                width: parent.width
                text: card.notif.summary
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }
            Label {
                width: parent.width
                visible: text !== ""
                text: card.notif.body
                textFormat: Text.StyledText
                wrapMode: Text.Wrap
                maximumLineCount: card.popup ? 4 : 8
                color: Theme.textMuted
                onLinkActivated: link => Qt.openUrlExternally(link)
            }

            Flow {
                width: parent.width
                spacing: 6
                topPadding: 4
                visible: actionRepeater.count > 0

                Repeater {
                    id: actionRepeater
                    model: card.notif.actions.filter(a => a.identifier !== "default")

                    Chip {
                        required property var modelData
                        onClicked: modelData.invoke()
                        Label { text: modelData.text }
                    }
                }
            }
        }
    }

    // close button
    Icon {
        anchors { right: parent.right; top: parent.top; margins: 8 }
        name: "close"
        font.pixelSize: 16
        color: closeArea.containsMouse ? Theme.text : Theme.outline

        MouseArea {
            id: closeArea
            anchors.fill: parent
            anchors.margins: -4
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: card.notif.dismiss()
        }
    }
}
