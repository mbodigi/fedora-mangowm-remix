// System tray: left click activates, right click opens the app's menu.
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../services"

Chip {
    id: root
    visible: SystemTray.items.values.length > 0

    Repeater {
        model: SystemTray.items

        Item {
            id: entry
            required property var modelData
            width: 18
            height: 18
            anchors.verticalCenter: parent.verticalCenter

            IconImage {
                anchors.fill: parent
                source: {
                    const icon = entry.modelData.icon;
                    // some apps pass "name?path=/dir"; turn that into a file path
                    if (icon.includes("?path=")) {
                        const [name, path] = icon.split("?path=");
                        return "file://" + path + "/" + name.slice(name.lastIndexOf("/") + 1);
                    }
                    return icon;
                }
            }

            QsMenuAnchor {
                id: menu
                menu: entry.modelData.menu
                anchor.item: entry
                anchor.edges: Edges.Bottom
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor
                onClicked: mouse => {
                    const item = entry.modelData;
                    if (mouse.button === Qt.RightButton || (item.onlyMenu && item.hasMenu))
                        menu.open();
                    else if (mouse.button === Qt.MiddleButton)
                        item.secondaryActivate();
                    else
                        item.activate();
                }
            }
        }
    }
}
