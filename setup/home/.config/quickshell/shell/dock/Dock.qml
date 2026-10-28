// Left-side dock (replaces the Waybar dock): pinned apps + running windows, one icon per app.
// Click: focus the app's window, or minimize it if it's focused, or start it. Middle click: close.
// Right click: Pin to dock / Unpin, New window, Close. Pins are saved in Settings ("dockPins").
// Intelli-hide like the old dock: shown when no window overlaps its strip, or while the pointer is at
// the left edge / on the dock; always hidden over fullscreen windows.
// IPC: qs -c shell ipc call dock togglePin   (pin / unpin the focused app, Super+Shift+P)
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../services"

Scope {
    id: root

    readonly property int zone: 56          // px from the left edge the dock occupies
    readonly property var ignore: ["dev.dropdown.ghostty"]
    readonly property var pins: Settings.get("dockPins")

    // desktop entry id for a window's app id ("" if there's no launcher for it)
    function entryFor(appId) {
        const e = DesktopEntries.byId(appId) ?? DesktopEntries.heuristicLookup(appId);
        return e ?? null;
    }

    // pinned apps first (in pin order), then other running apps in the order they opened
    readonly property var items: {
        DesktopEntries.applications.values;   // re-evaluate once the app list has loaded
        const list = [];
        for (const id of root.pins) {
            const e = DesktopEntries.byId(id);
            if (e) list.push({ key: id, entry: e, pinned: true, windows: [] });
        }
        for (const t of ToplevelManager.toplevels.values) {
            if (!t.appId || root.ignore.includes(t.appId)) continue;
            const e = root.entryFor(t.appId);
            const key = e ? e.id : t.appId;
            const item = list.find(i => i.key === key);
            if (item) item.windows.push(t);
            else list.push({ key: key, entry: e, pinned: false, windows: [t] });
        }
        return list;
    }

    function isPinned(id) { return root.pins.includes(id); }

    function setPinned(id, on) {
        const p = root.pins.filter(x => x !== id);
        if (on) p.push(id);
        Settings.set("dockPins", p);
    }

    function togglePinFocused() {
        const e = root.entryFor(Mango.focusedAppId);
        if (!e) {
            Quickshell.execDetached(["notify-send", "-a", "Dock", "Can't pin this window", "No app launcher found for it"]);
            return;
        }
        const on = !root.isPinned(e.id);
        root.setPinned(e.id, on);
        Quickshell.execDetached(["notify-send", "-a", "Dock", "-i", e.icon || "view-pin",
                                 (on ? "Pinned " : "Unpinned ") + e.name + (on ? " to the dock" : "")]);
    }

    // where windows are, for intelli-hide: [{monitor, x, visible, minimized, fullscreen}]
    property var clients: []
    Process {
        id: poll
        command: ["mmsg", "get", "all-clients"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.clients = JSON.parse(this.text).clients ?? []; } catch (e) {}
            }
        }
    }
    Timer {
        interval: 300
        running: true
        repeat: true
        onTriggered: if (!poll.running) poll.running = true
    }

    Variants {
        model: Quickshell.screens

        Scope {
            id: perScreen
            required property var modelData

            property bool edgeHovered: false
            property bool dockHovered: false
            property bool menuOpen: false

            readonly property string blocker: {
                for (const c of root.clients) {
                    if (c.monitor !== modelData.name || !c.is_visible || c.is_minimized) continue;
                    if (c.is_fullscreen) return "fullscreen";
                    if (c.x < modelData.x + root.zone) return "overlap";
                }
                return "";
            }
            readonly property bool wanted: blocker !== "fullscreen"
                && (edgeHovered || dockHovered || menuOpen || blocker === "")
            // show at once, hide after a short grace period so moving the pointer
            // around the dock doesn't make it vanish
            property bool shown: false
            onWantedChanged: {
                if (wanted) { hideDelay.stop(); shown = true; }
                else if (blocker === "fullscreen") { hideDelay.stop(); shown = false; }
                else hideDelay.restart();
            }
            Timer { id: hideDelay; interval: 500; onTriggered: perScreen.shown = perScreen.wanted }

            // pinning (or an app opening/closing) rebuilds the icons, and an icon destroyed with its
            // menu open never reports the menu closing; any open menu is gone with it, so reset
            Connections {
                target: root
                function onItemsChanged() { perScreen.menuOpen = false; }
            }
            Component.onCompleted: shown = wanted

            // 1px strip at the left edge that reveals the dock
            PanelWindow {
                screen: perScreen.modelData
                anchors { left: true; top: true; bottom: true }
                implicitWidth: 1
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "shell-dock-edge"
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onContainsMouseChanged: perScreen.edgeHovered = containsMouse
                }
            }

            PanelWindow {
                id: dock
                screen: perScreen.modelData
                visible: perScreen.shown && root.items.length > 0
                // flush with the screen edge, so the reveal strip and the dock touch
                anchors.left: true
                implicitWidth: 56
                implicitHeight: column.implicitHeight + 16
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "shell-dock"

                HoverHandler { onHoveredChanged: perScreen.dockHovered = hovered }

                // solid, in the gray the bar's workspace block shows (surface_container_high).
                // It reaches past the screen edge so only the right corners are rounded.
                Rectangle {
                    x: -radius
                    width: parent.width + radius
                    height: parent.height
                    radius: 14
                    color: Theme.surfaceHigh

                    Column {
                        id: column
                        anchors { verticalCenter: parent.verticalCenter; right: parent.right; rightMargin: 4 }
                        spacing: 4

                        Repeater {
                            model: root.items
                            DockItem {
                                required property var modelData
                                item: modelData
                                dock: root
                                window: dock
                                onMenuOpenChanged: perScreen.menuOpen = menuOpen
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "dock"
        function togglePin(): void { root.togglePinFocused(); }
    }
}
