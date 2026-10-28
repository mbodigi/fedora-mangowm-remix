// Mango tags 1-9 as numbers: active = filled pill, occupied = bright, empty = faint. Click to view, scroll to cycle.
import QtQuick
import "../services"

Chip {
    id: root
    hoverEffect: false   // the block stays the same color; only the tags react

    onWheel: event => {
        const active = Mango.tags.findIndex(t => t.is_active);
        const n = Mango.tags.length || 9;
        const next = ((active + (event.angleDelta.y < 0 ? 1 : -1)) % n + n) % n;
        Mango.viewTag(next + 1);
    }

    Repeater {
        model: Mango.tags

        Rectangle {
            id: tag
            required property var modelData
            anchors.verticalCenter: parent.verticalCenter
            width: 20
            height: 20
            radius: 10
            color: modelData.is_active ? (root.flat ? Theme.grayAccent : Theme.primary) : "transparent"

            Label {
                anchors.centerIn: parent
                text: tag.modelData.index
                font.weight: tag.modelData.is_active ? Font.Bold : Font.Normal
                color: tag.modelData.is_urgent ? Theme.error
                     : tag.modelData.is_active ? (root.flat ? Theme.text : Theme.textOnPrimary)
                     : tag.modelData.client_count > 0 ? Theme.text
                     : Theme.outline
                opacity: tag.modelData.is_active || tag.modelData.client_count > 0 ? 1 : 0.5
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Mango.viewTag(tag.modelData.index)
            }
        }
    }
}
