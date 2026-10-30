pragma Singleton
// Notification daemon: keeps a history and a list of on-screen popups.
// Only one daemon can own notifications on the session bus.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Singleton {
    id: root

    property list<QtObject> popups: []    // notifications currently shown as popups
    property bool dnd: false              // do not disturb: keep history, no popups
    property bool centerOpen: false

    readonly property var history: server.trackedNotifications.values
    readonly property int count: history.length

    function dismissPopup(n) {
        root.popups = root.popups.filter(p => p !== n);
    }

    function clearAll() {
        for (const n of [...root.history])
            n.dismiss();
        root.popups = [];
    }

    NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: n => {
            n.tracked = true;
            n.closed.connect(() => root.dismissPopup(n));
            if (!root.dnd || n.urgency === NotificationUrgency.Critical)
                root.popups = [n, ...root.popups].slice(0, 5);
        }
    }

    IpcHandler {
        target: "notifications"
        function toggleCenter(): void { root.centerOpen = !root.centerOpen; }
        function toggleDnd(): void { root.dnd = !root.dnd; }
        function clear(): void { root.clearAll(); }
    }
}
