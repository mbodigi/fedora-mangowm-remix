// All apps: every app as an icon grid, A-Z. Type to filter, arrows to move, Enter to launch, Esc or click outside to close.
// Toggle with: qs -c shell ipc call apps toggle
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import "../services"
import "../bar"

PanelWindow {
    id: root

    visible: false
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "shell-apps"

    property var apps: []

    function open() {
        search.text = "";
        refresh();
        visible = true;
        search.forceActiveFocus();
    }

    function close() { visible = false; }

    function refresh() {
        const q = search.text.trim().toLowerCase();
        apps = DesktopEntries.applications.values
            .filter(a => !a.noDisplay)
            .filter(a => q === ""
                || (a.name ?? "").toLowerCase().includes(q)
                || (a.genericName ?? "").toLowerCase().includes(q)
                || (a.keywords ?? []).some(k => k.toLowerCase().startsWith(q)))
            .sort((a, b) => a.name.localeCompare(b.name));
        grid.currentIndex = 0;
    }

    function launch(app) {
        if (!app) return;
        app.execute();
        close();
    }

    IpcHandler {
        target: "apps"
        function toggle(): void { root.visible ? root.close() : root.open(); }
        function open(): void { root.open(); }
        function close(): void { root.close(); }
    }

    // click outside the box closes it
    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Rectangle {
        id: box
        readonly property int cols: Math.max(3, Math.min(7, Math.floor((root.width * 0.8 - 24) / grid.cellWidth)))
        width: cols * grid.cellWidth + 24
        height: Math.min(root.height * 0.75, 44 + 8 + 24 + Math.ceil(Math.max(root.apps.length, 1) / cols) * grid.cellHeight)
        anchors.centerIn: parent
        radius: 18
        color: Theme.surface
        border.color: Theme.surfaceHigh
        border.width: 1

        MouseArea { anchors.fill: parent }   // swallow clicks inside

        Rectangle {
            id: searchBox
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
            height: 44
            radius: 12
            color: Theme.surfaceContainer

            Icon {
                id: searchIcon
                name: "search"
                anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                color: Theme.textMuted
            }

            TextInput {
                id: search
                anchors { left: searchIcon.right; right: parent.right; leftMargin: 10; rightMargin: 12; verticalCenter: parent.verticalCenter }
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: 16
                clip: true
                onTextChanged: root.refresh()

                Keys.onPressed: event => {
                    const n = root.apps.length;
                    if (event.key === Qt.Key_Escape) {
                        root.close();
                    } else if (event.key === Qt.Key_Right || (event.key === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier))) {
                        grid.currentIndex = Math.min(grid.currentIndex + 1, n - 1);
                    } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab) {
                        grid.currentIndex = Math.max(grid.currentIndex - 1, 0);
                    } else if (event.key === Qt.Key_Down) {
                        grid.currentIndex = Math.min(grid.currentIndex + box.cols, n - 1);
                    } else if (event.key === Qt.Key_Up) {
                        grid.currentIndex = Math.max(grid.currentIndex - box.cols, 0);
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.launch(root.apps[grid.currentIndex]);
                    } else {
                        return;
                    }
                    event.accepted = true;
                }

                Label {
                    visible: search.text === ""
                    text: "All apps — type to filter…"
                    color: Theme.outline
                    font.pixelSize: 16
                }
            }
        }

        GridView {
            id: grid
            anchors { left: parent.left; right: parent.right; top: searchBox.bottom; bottom: parent.bottom; margins: 12; topMargin: 8 }
            cellWidth: 112
            cellHeight: 104
            clip: true
            model: root.apps
            boundsBehavior: Flickable.StopAtBounds

            delegate: Rectangle {
                id: cell
                required property var modelData
                required property int index
                width: grid.cellWidth - 6
                height: grid.cellHeight - 6
                radius: 12
                color: index === grid.currentIndex ? Theme.surfaceHigh : "transparent"

                IconImage {
                    id: appIcon
                    anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 12 }
                    implicitSize: 44
                    source: Quickshell.iconPath(cell.modelData.icon, "application-x-executable")
                }

                Label {
                    anchors { left: parent.left; right: parent.right; top: appIcon.bottom; topMargin: 8; leftMargin: 6; rightMargin: 6 }
                    text: cell.modelData.name
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: 12
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: grid.currentIndex = cell.index
                    onClicked: root.launch(cell.modelData)
                }
            }
        }

        Label {
            visible: root.apps.length === 0
            anchors.centerIn: grid
            text: "No apps found"
            color: Theme.outline
        }
    }
}
