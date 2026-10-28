// App launcher: type to search, Up/Down to pick, Enter to launch, Esc or click outside to close.
// Toggle with: qs -c shell ipc call launcher toggle
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
    WlrLayershell.namespace: "shell-launcher"

    property var usage: ({})   // desktop entry id -> launch count, for ranking
    property var results: []
    property int selected: 0

    function open() {
        search.text = "";
        refresh();
        visible = true;
        search.forceActiveFocus();
    }

    function close() { visible = false; }

    function score(app, q) {
        const name = (app.name ?? "").toLowerCase();
        let s = 0;
        if (q === "") s = 1;
        else if (name.startsWith(q)) s = 100;
        else if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q))) s = 80;
        else if (name.includes(q)) s = 60;
        else if ((app.genericName ?? "").toLowerCase().includes(q)) s = 40;
        else if ((app.keywords ?? []).some(k => k.toLowerCase().startsWith(q))) s = 35;
        else if ((app.comment ?? "").toLowerCase().includes(q)) s = 20;
        if (s === 0) return 0;
        return s + Math.min(usage[app.id] ?? 0, 30);
    }

    function refresh() {
        const q = search.text.trim().toLowerCase();
        results = DesktopEntries.applications.values
            .filter(a => !a.noDisplay)
            .map(a => ({ app: a, s: score(a, q) }))
            .filter(r => r.s > 0)
            .sort((a, b) => b.s - a.s || a.app.name.localeCompare(b.app.name))
            .slice(0, 8)
            .map(r => r.app);
        selected = 0;
    }

    function launch(app) {
        if (!app) return;
        const u = Object.assign({}, usage);
        u[app.id] = (u[app.id] ?? 0) + 1;
        usage = u;
        usageFile.setText(JSON.stringify(usage));
        app.execute();
        close();
    }

    FileView {
        id: usageFile
        path: Quickshell.env("HOME") + "/.local/state/shell/launcher-usage.json"
        onLoaded: { try { root.usage = JSON.parse(usageFile.text()); } catch (e) {} }
        onLoadFailed: root.usage = {}
    }

    IpcHandler {
        target: "launcher"
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
        width: 560
        height: column.implicitHeight + 24
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.18
        radius: 18
        color: Theme.surface
        border.color: Theme.surfaceHigh
        border.width: 1

        MouseArea { anchors.fill: parent }   // swallow clicks inside

        Column {
            id: column
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
            spacing: 8

            Rectangle {
                width: parent.width
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
                        if (event.key === Qt.Key_Escape) {
                            root.close();
                        } else if (event.key === Qt.Key_Down || (event.key === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier))) {
                            root.selected = Math.min(root.selected + 1, root.results.length - 1);
                        } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab) {
                            root.selected = Math.max(root.selected - 1, 0);
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.launch(root.results[root.selected]);
                        } else {
                            return;
                        }
                        event.accepted = true;
                    }

                    Label {
                        visible: search.text === ""
                        text: "Search apps…"
                        color: Theme.outline
                        font.pixelSize: 16
                    }
                }
            }

            Repeater {
                model: root.results

                Rectangle {
                    id: row
                    required property var modelData
                    required property int index
                    width: column.width
                    height: 48
                    radius: 12
                    color: index === root.selected ? Theme.surfaceHigh : "transparent"

                    IconImage {
                        id: appIcon
                        anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                        implicitSize: 32
                        source: Quickshell.iconPath(row.modelData.icon, "application-x-executable")
                    }

                    Column {
                        anchors { left: appIcon.right; right: parent.right; leftMargin: 12; rightMargin: 10; verticalCenter: parent.verticalCenter }
                        Label {
                            width: parent.width
                            text: row.modelData.name
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                        }
                        Label {
                            width: parent.width
                            visible: text !== ""
                            text: row.modelData.comment || row.modelData.genericName || ""
                            color: Theme.textMuted
                            font.pixelSize: 12
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.selected = row.index
                        onClicked: root.launch(row.modelData)
                    }
                }
            }

            Label {
                visible: root.results.length === 0
                text: "No apps found"
                color: Theme.outline
                leftPadding: 12
                height: 32
            }
        }
    }
}
