// One app in the dock: icon, a line on the left while it has windows (brighter when focused),
// faded while all its windows are minimized, and a right-click menu.
import QtQuick
import Quickshell
import Quickshell.Widgets
import "../services"
import "../bar"

Item {
    id: root

    required property var item      // {key, entry, pinned, windows}
    required property var dock      // Dock.qml (pin helpers)
    required property var window    // the dock's PanelWindow (menu anchor)
    property bool menuOpen: menu.visible

    readonly property var windows: item.windows
    readonly property bool running: windows.length > 0
    readonly property bool focused: windows.some(w => w.activated)
    readonly property bool allMinimized: running && windows.every(w => w.minimized)
    readonly property string name: item.entry ? item.entry.name : (windows[0]?.title ?? item.key)

    width: 48
    height: 48

    function launch() {
        if (item.entry) item.entry.execute();
    }

    // like the old dock's minimize-raise: a focused app minimizes, anything else comes forward
    function clicked() {
        if (!running) { launch(); return; }
        const f = windows.find(w => w.activated && !w.minimized);
        if (f) { f.minimized = true; return; }
        const w = windows.find(w => w.minimized) ?? windows[0];
        w.minimized = false;
        w.activate();
    }

    Rectangle {
        anchors.fill: parent
        radius: 12
        // hover = the gray of the bar's active workspace pill
        color: mouse.containsMouse || root.menuOpen ? Theme.grayAccent : "transparent"
    }

    // running indicator on the dock's outer edge
    Rectangle {
        visible: root.running
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        width: 3
        height: root.focused ? 22 : 8
        radius: 2
        color: root.focused ? Theme.accentLine : Qt.rgba(1, 1, 1, 0.45)
        Behavior on height { NumberAnimation { duration: 120 } }
    }

    IconImage {
        anchors.centerIn: parent
        implicitSize: 36
        opacity: root.allMinimized ? 0.45 : 1
        source: Quickshell.iconPath(root.item.entry?.icon ?? root.item.key, "application-x-executable")
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: m => {
            if (m.button === Qt.RightButton) menu.visible = !menu.visible;
            else if (m.button === Qt.MiddleButton) { for (const w of root.windows) w.close(); }
            else root.clicked();
        }
    }

    // tooltip-style name while hovering
    PopupWindow {
        visible: mouse.containsMouse && !menu.visible
        anchor.item: root
        anchor.edges: Edges.Right
        anchor.gravity: Edges.Right
        anchor.margins.left: 10
        implicitWidth: tip.implicitWidth + 20
        implicitHeight: 28
        color: "transparent"
        Rectangle {
            anchors.fill: parent
            radius: 8
            color: Theme.surfaceHigh
            Label { id: tip; anchors.centerIn: parent; text: root.name }
        }
    }

    PopupWindow {
        id: menu
        visible: false
        anchor.item: root
        anchor.edges: Edges.Right
        anchor.gravity: Edges.Right
        anchor.margins.left: 10
        implicitWidth: 200
        implicitHeight: menuColumn.implicitHeight + 12
        color: "transparent"

        // close when the pointer leaves the menu for a moment
        HoverHandler { id: menuHover }
        Timer {
            running: menu.visible && !menuHover.hovered && !mouse.containsMouse
            interval: 700
            onTriggered: menu.visible = false
        }

        Rectangle {
            anchors.fill: parent
            radius: 12
            color: Theme.surfaceContainer
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.08)

            Column {
                id: menuColumn
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 6 }

                Label {
                    width: parent.width
                    leftPadding: 10
                    topPadding: 6
                    bottomPadding: 6
                    text: root.name
                    color: Theme.textMuted
                    elide: Text.ElideRight
                }

                MenuRow {
                    visible: root.item.entry !== null
                    icon: root.dock.isPinned(root.item.key) ? "keep_off" : "keep"
                    text: root.dock.isPinned(root.item.key) ? "Unpin from dock" : "Pin to dock"
                    onActivated: root.dock.setPinned(root.item.key, !root.dock.isPinned(root.item.key))
                }
                MenuRow {
                    visible: root.item.entry !== null
                    icon: "add"
                    text: root.running ? "New window" : "Open"
                    onActivated: root.launch()
                }
                MenuRow {
                    visible: root.running
                    icon: "close"
                    text: root.windows.length > 1 ? "Close all windows" : "Close"
                    onActivated: { for (const w of root.windows) w.close(); }
                }
            }
        }

        component MenuRow: Rectangle {
            id: row
            property string icon
            property string text
            signal activated()

            width: parent.width
            height: visible ? 34 : 0
            radius: 8
            color: rowMouse.containsMouse ? Theme.primary : "transparent"

            Row {
                anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                spacing: 10
                Icon { name: row.icon; anchors.verticalCenter: parent.verticalCenter }
                Label {
                    text: row.text
                    anchors.verticalCenter: parent.verticalCenter
                    color: rowMouse.containsMouse ? Theme.textOnPrimary : Theme.text
                }
            }

            MouseArea {
                id: rowMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: { row.activated(); menu.visible = false; }
            }
        }
    }
}
