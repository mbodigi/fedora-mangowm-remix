pragma Singleton
// Live mango state (tags, focused window) from `mmsg watch`, plus helpers to dispatch commands.
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var tags: []           // [{index, is_active, is_urgent, client_count}] for the focused monitor
    property string focusedTitle: ""
    property string focusedAppId: ""

    function dispatch(cmd) {
        Quickshell.execDetached(["mmsg", "dispatch", cmd]);
    }

    function viewTag(index) { dispatch("view," + index); }

    Process {
        id: tagWatch
        command: ["mmsg", "watch", "all-tags"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                try {
                    const mons = JSON.parse(line).all_tags;
                    if (mons && mons.length)
                        root.tags = mons[0].tags;
                } catch (e) {}
            }
        }
        // mmsg exits if mango restarts; try again
        onRunningChanged: if (!running) restartTags.start()
    }
    Timer { id: restartTags; interval: 2000; onTriggered: tagWatch.running = true }

    Process {
        id: focusWatch
        command: ["mmsg", "watch", "focusing-client"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                try {
                    const c = JSON.parse(line);
                    root.focusedTitle = c.title ?? "";
                    root.focusedAppId = c.appid ?? "";
                } catch (e) {
                    root.focusedTitle = "";
                    root.focusedAppId = "";
                }
            }
        }
        onRunningChanged: if (!running) restartFocus.start()
    }
    Timer { id: restartFocus; interval: 2000; onTriggered: focusWatch.running = true }
}
