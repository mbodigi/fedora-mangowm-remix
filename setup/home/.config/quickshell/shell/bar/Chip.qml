// Rounded, optionally clickable container for a bar widget.
// flat: faint gray block with small corners, lighter on hover (used by the "mac" bar style).
import QtQuick
import "../services"

Rectangle {
    id: chip

    default property alias content: row.data
    property bool highlighted: false
    property bool flat: false
    property bool hoverEffect: true
    signal clicked(var mouse)
    signal wheel(var event)

    implicitWidth: row.implicitWidth + (flat ? 12 : 16)
    implicitHeight: flat ? 22 : 26
    radius: flat ? 6 : height / 2
    // text/icon color to use on top of this chip
    readonly property color fg: highlighted && !flat ? Theme.textOnPrimary : Theme.text

    color: highlighted ? (flat ? Theme.grayAccent : Theme.primary)
         : area.containsMouse && hoverEffect ? (flat ? Qt.rgba(1, 1, 1, 0.2) : Theme.surfaceHigh)
         : (flat ? Qt.rgba(1, 1, 1, 0.12) : Theme.surfaceContainer)

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6
    }

    // below the contents, so items inside (tag numbers, tray icons) get their own clicks
    MouseArea {
        id: area
        z: -1
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => chip.clicked(mouse)
        onWheel: event => chip.wheel(event)
    }
}
