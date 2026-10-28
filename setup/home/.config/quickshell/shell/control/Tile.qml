// Quick-settings tile: click the tile to toggle, click the arrow (if any) to expand details.
import QtQuick
import "../services"
import "../bar"

Rectangle {
    id: tile

    property string icon
    property string title
    property string subtitle
    property bool active: false
    property bool expandable: false
    property bool expanded: false
    signal toggled()
    signal expandClicked()

    implicitHeight: 56
    radius: 16
    color: active ? Theme.primary : (area.containsMouse ? Theme.surfaceHigh : Theme.surface)

    readonly property color fg: active ? Theme.textOnPrimary : Theme.text

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: tile.toggled()
    }

    Icon {
        id: glyph
        anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
        name: tile.icon
        filled: tile.active
        color: tile.fg
        font.pixelSize: 22
    }

    Column {
        anchors { left: glyph.right; right: arrow.visible ? arrow.left : parent.right; leftMargin: 10; rightMargin: 8; verticalCenter: parent.verticalCenter }
        Label {
            width: parent.width
            text: tile.title
            color: tile.fg
            font.weight: Font.DemiBold
        }
        Label {
            width: parent.width
            visible: text !== ""
            text: tile.subtitle
            color: tile.fg
            opacity: 0.75
            font.pixelSize: 11
        }
    }

    Rectangle {
        id: arrow
        visible: tile.expandable
        anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
        width: 30
        height: 30
        radius: 15
        color: arrowArea.containsMouse ? Qt.rgba(0.5, 0.5, 0.5, 0.25) : "transparent"

        Icon {
            anchors.centerIn: parent
            name: tile.expanded ? "expand_less" : "chevron_right"
            color: tile.fg
        }
        MouseArea {
            id: arrowArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.expandClicked()
        }
    }
}
