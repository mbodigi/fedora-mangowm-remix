// A clickable row in the control center's Wi-Fi / Bluetooth lists.
import QtQuick
import "../services"
import "../bar"

Rectangle {
    id: row

    property string icon
    property string title
    property string detail
    property string trailingIcon
    property bool highlighted: false
    signal clicked()

    implicitHeight: 44
    radius: 12
    color: area.containsMouse ? Theme.surfaceHigh : (highlighted ? Theme.surface : "transparent")

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: row.clicked()
    }

    Icon {
        id: glyph
        anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
        name: row.icon
        filled: row.highlighted
    }

    Column {
        anchors { left: glyph.right; right: trailing.left; leftMargin: 12; rightMargin: 8; verticalCenter: parent.verticalCenter }
        Label {
            width: parent.width
            text: row.title
            font.weight: row.highlighted ? Font.DemiBold : Font.Normal
        }
        Label {
            width: parent.width
            text: row.detail
            color: Theme.textMuted
            font.pixelSize: 11
        }
    }

    Icon {
        id: trailing
        anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
        name: row.trailingIcon
        visible: row.trailingIcon !== ""
        color: Theme.outline
        font.pixelSize: 16
    }
}
