// Month calendar with previous/next month buttons; today is highlighted.
import QtQuick
import "../services"
import "../bar"

Column {
    id: root

    property date shown: new Date()
    readonly property date today: new Date()
    readonly property int year: shown.getFullYear()
    readonly property int month: shown.getMonth()

    function shift(n) { shown = new Date(year, month + n, 1); }

    spacing: 6

    Item {
        width: parent.width
        height: 30
        Chip {
            anchors.left: parent.left
            onClicked: root.shift(-1)
            Icon { name: "chevron_left" }
        }
        Label {
            anchors.centerIn: parent
            text: Qt.formatDate(root.shown, "MMMM yyyy")
            font.pixelSize: 15
            font.weight: Font.DemiBold
        }
        Chip {
            anchors.right: parent.right
            onClicked: root.shift(1)
            Icon { name: "chevron_right" }
        }
    }

    Grid {
        columns: 7
        width: parent.width
        readonly property real cell: width / 7

        Repeater {
            model: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            Label {
                required property string modelData
                width: parent.cell
                height: 26
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                color: Theme.textMuted
                font.pixelSize: 12
            }
        }

        Repeater {
            // 6 weeks starting from the Sunday on/before the 1st
            model: 42
            Rectangle {
                required property int index
                readonly property date day: new Date(root.year, root.month, 1 + index - new Date(root.year, root.month, 1).getDay())
                readonly property bool inMonth: day.getMonth() === root.month
                readonly property bool isToday: day.toDateString() === root.today.toDateString()
                width: parent.cell
                height: 34
                radius: 17
                color: isToday ? Theme.primary : "transparent"
                Label {
                    anchors.centerIn: parent
                    text: parent.day.getDate()
                    color: parent.isToday ? Theme.textOnPrimary : parent.inMonth ? Theme.text : Theme.outline
                    opacity: parent.inMonth ? 1 : 0.5
                    font.weight: parent.isToday ? Font.Bold : Font.Normal
                }
            }
        }
    }
}
