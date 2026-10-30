// Keybind cheat sheet (Super+Shift+/): reads the mango config, groups binds by "# === Section ===" headers,
// and uses the comment line above each bind as its description. Type to filter.
// Toggle with: qs -c shell ipc call cheatsheet toggle
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
    WlrLayershell.namespace: "shell-cheatsheet"

    property var sections: []   // [{title, binds: [{keys, desc}]}]

    readonly property var filtered: {
        const q = search.text.trim().toLowerCase();
        if (!q) return sections;
        return sections.map(s => ({ title: s.title, binds: s.binds.filter(b => (b.keys + " " + b.desc).toLowerCase().includes(q)) }))
                       .filter(s => s.binds.length > 0);
    }

    function prettyKeys(mods, key, kind) {
        const names = { SUPER: "Super", SHIFT: "Shift", CTRL: "Ctrl", ALT: "Alt", NONE: "" };
        const m = mods.split("+").map(x => names[x.toUpperCase()] ?? x).filter(x => x);
        let k = key;
        const special = { Return: "Enter", space: "Space", grave: "`", comma: ",", period: ".", slash: "/", minus: "-", equal: "=",
                          Tab: "Tab", Left: "←", Right: "→", Up: "↑", Down: "↓", Delete: "Del" };
        if (special[k]) k = special[k];
        else if (k.startsWith("XF86")) k = k.slice(4).replace(/([a-z])([A-Z])/g, "$1 $2");
        else if (k.length === 1) k = k.toUpperCase();
        if (kind === "gesturebind") return mods.replace(/^none$/i, "") + key + " swipe";
        if (kind === "mousebind") return m.concat([key.replace("btn_", "").replace("left", "Left click").replace("right", "Right click").replace("middle", "Middle click")]).join(" + ");
        return m.concat([k]).join(" + ");
    }

    // readable name for a bind action when there is no description comment
    function describe(action) {
        const words = { killclient: "Close window", minimized: "Minimize window", restore_minimized: "Restore minimized window",
                        togglemaximizescreen: "Maximize", togglefullscreen: "Fullscreen", togglefakefullscreen: "Fake fullscreen",
                        togglefloating: "Float / tile window", toggleoverview: "Overview", toggle_scratchpad: "Show scratchpad",
                        toggle_named_scratchpad: "Drop-down terminal", switch_layout: "Next layout", reload_config: "Reload config",
                        quit: "Log out", focusstack: "Focus next window", focusdir: "Focus", exchange_client: "Swap window",
                        view: "Go to tag", tag: "Move window to tag", viewtoleft: "Previous tag", viewtoright: "Next tag",
                        tagtoleft: "Move window to previous tag", tagtoright: "Move window to next tag", resizewin: "Resize window",
                        movewin: "Move window", setmfact: "Resize main area", incnmaster: "Change main window count" };
        const parts = action.split(",");
        const ipc = action.match(/ipc call (\S+) (\S+)/);
        if (ipc) return (ipc[2] + " (" + ipc[1] + ")").replace(/([a-z])([A-Z])/g, "$1 $2").replace(/^./, c => c.toUpperCase());
        if (parts[0] === "spawn") return "Run " + parts.slice(1).join(",").split(" ")[0];
        const base = words[parts[0]] ?? parts[0].replace(/_/g, " ");
        const arg = parts.slice(1).filter(a => a && !a.includes(".") && a.length < 10).join(" ");
        return arg && !words[parts[0]]?.includes("terminal") ? base + " " + arg : base;
    }

    function parse(texts) {
        const out = [];
        let current = { title: "General", binds: [] };
        for (const text of texts) {
            let desc = "";
            for (const raw of text.split("\n")) {
                const line = raw.trim();
                const header = line.match(/^#\s*===\s*(.+?)\s*===/);
                if (header) {
                    if (current.binds.length) out.push(current);
                    current = { title: header[1], binds: [] };
                    desc = "";
                    continue;
                }
                if (line.startsWith("#")) { desc = line.replace(/^#\s*/, ""); continue; }
                const m = line.match(/^(bind[a-z]*|mousebind|gesturebind)\s*=\s*([^,]*),([^,]*),(.*)$/);
                if (m) {
                    const action = m[4].replace(/,\s*$/, "");
                    // descriptions written as full sentences are notes, not labels
                    const label = desc && desc.length < 60 ? desc : root.describe(action);
                    current.binds.push({ keys: prettyKeys(m[2], m[3], m[1]), desc: label });
                }
                if (!line.startsWith("#")) desc = "";
            }
        }
        if (current.binds.length) out.push(current);
        sections = out;
    }

    function open() {
        search.text = "";
        reader.running = true;
        visible = true;
        search.forceActiveFocus();
    }

    Process {
        id: reader
        command: ["sh", "-c", "cat ~/.config/mango/config.conf; printf '\\n\\x1e\\n'; cat ~/.config/mango/conf.d/binds.conf"]
        stdout: StdioCollector {
            onStreamFinished: root.parse(text.split("\x1e"))
        }
    }

    IpcHandler {
        target: "cheatsheet"
        function toggle(): void { root.visible ? root.visible = false : root.open(); }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.visible = false
    }

    Rectangle {
        anchors.centerIn: parent
        width: Math.min(parent.width - 80, 1500)
        height: Math.min(parent.height - 80, 900)
        radius: 24
        color: Theme.surface
        border.width: 1
        border.color: Theme.surfaceHigh

        MouseArea { anchors.fill: parent }   // swallow clicks inside

        Rectangle {
            id: searchBox
            anchors { top: parent.top; horizontalCenter: parent.horizontalCenter; topMargin: 16 }
            width: 420
            height: 40
            radius: 20
            color: Theme.surfaceContainer
            Icon {
                id: icon
                name: "keyboard"
                anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
                color: Theme.textMuted
            }
            TextInput {
                id: search
                anchors { left: icon.right; right: parent.right; leftMargin: 10; rightMargin: 14; verticalCenter: parent.verticalCenter }
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: 15
                Keys.onEscapePressed: root.visible = false
                Label {
                    visible: search.text === ""
                    text: "Keyboard shortcuts — type to filter"
                    color: Theme.outline
                    font.pixelSize: 15
                }
            }
        }

        Flickable {
            anchors { left: parent.left; right: parent.right; top: searchBox.bottom; bottom: parent.bottom; margins: 18 }
            contentHeight: flow.implicitHeight
            clip: true

            Flow {
                id: flow
                width: parent.width
                spacing: 14

                Repeater {
                    model: root.filtered

                    Rectangle {
                        id: section
                        required property var modelData
                        width: (flow.width - 2 * 14) / 3
                        height: col.implicitHeight + 24
                        radius: 16
                        color: Theme.surfaceContainer

                        Column {
                            id: col
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                            spacing: 4

                            Label {
                                text: section.modelData.title
                                font.weight: Font.Bold
                                color: Theme.text
                                bottomPadding: 4
                            }

                            Repeater {
                                model: section.modelData.binds
                                Item {
                                    required property var modelData
                                    width: col.width
                                    height: 24
                                    Label {
                                        id: keyLabel
                                        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                                        width: 170
                                        text: parent.modelData.keys
                                        font.family: "monospace"
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                    }
                                    Label {
                                        anchors { left: keyLabel.right; right: parent.right; leftMargin: 8; verticalCenter: parent.verticalCenter }
                                        text: parent.modelData.desc
                                        color: Theme.textMuted
                                        font.pixelSize: 12
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
