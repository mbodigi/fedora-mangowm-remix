// Clipboard history: type to filter, Up/Down to pick, Enter copies it back (then Ctrl+V to paste),
// Delete removes an entry. Toggle with: qs -c shell ipc call clipboard toggle
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
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
    WlrLayershell.namespace: "shell-clipboard"

    property int selected: 0
    readonly property var results: {
        const q = search.text.trim().toLowerCase();
        return Clipboard.entries.filter(e => q === "" || (!e.isImage && e.text.toLowerCase().includes(q))).slice(0, 50);
    }
    onResultsChanged: selected = Math.min(selected, Math.max(0, results.length - 1))

    function open() {
        search.text = "";
        selected = 0;
        Clipboard.refresh();
        visible = true;
        search.forceActiveFocus();
    }

    function close() { visible = false; }

    function pick(entry) {
        if (!entry) return;
        Clipboard.copy(entry);
        close();
    }

    IpcHandler {
        target: "clipboard"
        function toggle(): void { root.visible ? root.close() : root.open(); }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Rectangle {
        width: 600
        height: 560
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.14
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
                name: "content_paste_search"
                anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                color: Theme.textMuted
            }

            TextInput {
                id: search
                anchors { left: searchIcon.right; right: wipe.left; leftMargin: 10; rightMargin: 8; verticalCenter: parent.verticalCenter }
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: 16
                clip: true

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) root.close();
                    else if (event.key === Qt.Key_Down) root.selected = Math.min(root.selected + 1, root.results.length - 1);
                    else if (event.key === Qt.Key_Up) root.selected = Math.max(root.selected - 1, 0);
                    else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) root.pick(root.results[root.selected]);
                    else if (event.key === Qt.Key_Delete && root.results[root.selected]) Clipboard.remove(root.results[root.selected]);
                    else return;
                    list.positionViewAtIndex(root.selected, ListView.Contain);
                    event.accepted = true;
                }

                Label {
                    visible: search.text === ""
                    text: "Search clipboard…"
                    color: Theme.outline
                    font.pixelSize: 16
                }
            }

            Chip {
                id: wipe
                anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                visible: Clipboard.entries.length > 0
                onClicked: Clipboard.wipe()
                Icon { name: "delete_sweep" }
                Label { text: "Clear" }
            }
        }

        ListView {
            id: list
            anchors { left: parent.left; right: parent.right; top: searchBox.bottom; bottom: parent.bottom; margins: 12 }
            clip: true
            spacing: 4
            model: root.results

            delegate: Rectangle {
                id: row
                required property var modelData
                required property int index
                width: list.width
                height: modelData.isImage ? 96 : 44
                radius: 12
                color: index === root.selected ? Theme.surfaceHigh : "transparent"

                Image {
                    visible: row.modelData.isImage
                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom; margins: 6; leftMargin: 12 }
                    width: 160
                    fillMode: Image.PreserveAspectFit
                    horizontalAlignment: Image.AlignLeft
                    asynchronous: true
                    source: row.modelData.isImage ? "file://" + Clipboard.thumbDir + "/" + row.modelData.id : ""
                    sourceSize.height: 84
                }

                Label {
                    visible: !row.modelData.isImage
                    anchors { left: parent.left; right: parent.right; leftMargin: 14; rightMargin: 14; verticalCenter: parent.verticalCenter }
                    text: row.modelData.text.replace(/\s+/g, " ")
                    maximumLineCount: 1
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.selected = row.index
                    onClicked: mouse => mouse.button === Qt.MiddleButton ? Clipboard.remove(row.modelData) : root.pick(row.modelData)
                }
            }
        }

        Label {
            anchors.centerIn: parent
            visible: root.results.length === 0
            text: Clipboard.entries.length === 0 ? "Nothing copied yet" : "No matches"
            color: Theme.outline
        }
    }
}
