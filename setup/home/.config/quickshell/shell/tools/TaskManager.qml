// Task manager (Ctrl+Alt+Del): processes sorted by CPU or memory, refreshed every 2 s.
// Select a row and press End task (asks to confirm); Force quit if it won't close.
// Toggle with: qs -c shell ipc call tasks toggle
import QtQuick
import QtQuick.Layouts
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
    WlrLayershell.namespace: "shell-tasks"

    property var procs: []          // [{pid, user, cpu, mem, rss, name, cmd}]
    property string sortBy: "cpu"
    property int selectedPid: -1
    property int confirmPid: -1
    readonly property string me: Quickshell.env("USER")

    readonly property var shown: {
        const q = search.text.trim().toLowerCase();
        return procs.filter(p => !q || p.name.toLowerCase().includes(q) || p.cmd.toLowerCase().includes(q))
                    .sort((a, b) => sortBy === "cpu" ? b.cpu - a.cpu : b.rss - a.rss)
                    .slice(0, 60);
    }
    readonly property var selected: procs.find(p => p.pid === selectedPid) ?? null

    function open() {
        search.text = "";
        selectedPid = -1;
        confirmPid = -1;
        reader.running = true;
        visible = true;
        search.forceActiveFocus();
    }

    function kill(force) {
        if (!selected) return;
        if (!force && confirmPid !== selected.pid) { confirmPid = selected.pid; return; }
        Quickshell.execDetached(["kill", force ? "-KILL" : "-TERM", String(selected.pid)]);
        confirmPid = -1;
        selectedPid = -1;
        reader.running = true;
    }

    Process {
        id: reader
        command: ["ps", "-eo", "pid=,user=,pcpu=,pmem=,rss=,comm=,args=", "--sort=-pcpu"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.procs = text.split("\n").filter(l => l.trim()).map(l => {
                    const f = l.trim().split(/\s+/);
                    return { pid: Number(f[0]), user: f[1], cpu: Number(f[2]), mem: Number(f[3]), rss: Number(f[4]),
                             name: f[5], cmd: f.slice(6).join(" ") };
                }).filter(p => p.name !== "ps");
            }
        }
    }

    Timer {
        interval: 2000
        running: root.visible
        repeat: true
        onTriggered: reader.running = true
    }

    IpcHandler {
        target: "tasks"
        function toggle(): void { root.visible ? root.visible = false : root.open(); }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.visible = false
    }

    Rectangle {
        anchors.centerIn: parent
        width: 860
        height: 640
        radius: 24
        color: Theme.surface
        border.width: 1
        border.color: Theme.surfaceHigh

        MouseArea { anchors.fill: parent }   // swallow clicks inside

        ColumnLayout {
            anchors { fill: parent; margins: 16 }
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    height: 38
                    radius: 19
                    color: Theme.surfaceContainer
                    Icon {
                        id: searchIcon
                        name: "search"
                        anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
                        color: Theme.textMuted
                    }
                    TextInput {
                        id: search
                        anchors { left: searchIcon.right; right: parent.right; leftMargin: 10; rightMargin: 14; verticalCenter: parent.verticalCenter }
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: 14
                        Keys.onEscapePressed: root.visible = false
                        Label {
                            visible: search.text === ""
                            text: "Search processes…"
                            color: Theme.outline
                        }
                    }
                }

                Chip {
                    highlighted: root.sortBy === "cpu"
                    onClicked: root.sortBy = "cpu"
                    Label { text: "CPU"; color: root.sortBy === "cpu" ? Theme.textOnPrimary : Theme.text }
                }
                Chip {
                    highlighted: root.sortBy === "mem"
                    onClicked: root.sortBy = "mem"
                    Label { text: "Memory"; color: root.sortBy === "mem" ? Theme.textOnPrimary : Theme.text }
                }
            }

            // header
            Row {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Label { width: 300; text: "Name"; color: Theme.outline; font.pixelSize: 12 }
                Label { width: 90; text: "PID"; color: Theme.outline; font.pixelSize: 12 }
                Label { width: 110; text: "User"; color: Theme.outline; font.pixelSize: 12 }
                Label { width: 90; text: "CPU"; color: Theme.outline; font.pixelSize: 12; horizontalAlignment: Text.AlignRight }
                Label { width: 110; text: "Memory"; color: Theme.outline; font.pixelSize: 12; horizontalAlignment: Text.AlignRight }
            }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 2
                model: root.shown

                delegate: Rectangle {
                    id: row
                    required property var modelData
                    width: ListView.view.width
                    height: 32
                    radius: 8
                    color: modelData.pid === root.selectedPid ? Theme.surfaceHigh : area.containsMouse ? Theme.surfaceContainer : "transparent"

                    Row {
                        anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                        Label { width: 300; text: row.modelData.name; font.weight: Font.DemiBold }
                        Label { width: 90; text: row.modelData.pid; color: Theme.textMuted }
                        Label { width: 110; text: row.modelData.user; color: Theme.textMuted }
                        Label { width: 90; text: row.modelData.cpu.toFixed(1) + "%"; horizontalAlignment: Text.AlignRight }
                        Label {
                            width: 110
                            horizontalAlignment: Text.AlignRight
                            text: row.modelData.rss > 1048576 ? (row.modelData.rss / 1048576).toFixed(1) + " GB" : Math.round(row.modelData.rss / 1024) + " MB"
                        }
                    }

                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: { root.selectedPid = row.modelData.pid; root.confirmPid = -1; }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Label {
                    Layout.fillWidth: true
                    text: root.selected ? root.selected.cmd : root.procs.length + " processes · CPU " + Math.round(SysStats.cpu) + "% · RAM " + SysStats.memUsedGiB.toFixed(1) + " GB"
                    color: Theme.textMuted
                    font.pixelSize: 12
                }
                Chip {
                    visible: root.selected !== null && root.selected.user === root.me
                    highlighted: root.confirmPid === root.selectedPid
                    onClicked: root.kill(false)
                    Icon { name: "close"; color: root.confirmPid === root.selectedPid ? Theme.textOnPrimary : Theme.text }
                    Label { text: root.confirmPid === root.selectedPid ? "Click again to end" : "End task"; color: root.confirmPid === root.selectedPid ? Theme.textOnPrimary : Theme.text }
                }
                Chip {
                    visible: root.selected !== null && root.selected.user === root.me && root.confirmPid === root.selectedPid
                    onClicked: root.kill(true)
                    Icon { name: "dangerous"; color: Theme.error }
                    Label { text: "Force quit"; color: Theme.error }
                }
            }
        }
    }
}
