// Horizontal slider with a leading icon. `value` is 0-1; `moved(v)` fires while dragging or clicking.
import QtQuick
import "../services"
import "../bar"

Item {
    id: root

    property real value: 0
    property string icon
    signal moved(real v)
    signal iconClicked()

    implicitHeight: 40

    Icon {
        id: glyph
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        name: root.icon
        font.pixelSize: 20

        MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            cursorShape: Qt.PointingHandCursor
            onClicked: root.iconClicked()
        }
    }

    Rectangle {
        id: track
        anchors { left: glyph.right; right: parent.right; leftMargin: 14; verticalCenter: parent.verticalCenter }
        height: 10
        radius: 5
        color: Theme.surfaceHigh

        Rectangle {
            width: Math.max(height, parent.width * Math.max(0, Math.min(1, root.value)))
            height: parent.height
            radius: 5
            color: Theme.accentLine
        }

        MouseArea {
            anchors.fill: parent
            anchors.margins: -8
            cursorShape: Qt.PointingHandCursor
            function update(mouse) {
                root.moved(Math.max(0, Math.min(1, (mouse.x - 8) / track.width)));
            }
            onPressed: mouse => update(mouse)
            onPositionChanged: mouse => { if (pressed) update(mouse); }
            onWheel: wheel => root.moved(Math.max(0, Math.min(1, root.value + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))))
        }
    }
}
