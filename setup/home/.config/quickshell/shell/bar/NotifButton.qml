// Bell: shows the unread count, click opens the notification history, right click toggles do-not-disturb.
import QtQuick
import "../services"

Chip {
    id: root
    highlighted: Notifs.centerOpen
    onClicked: mouse => {
        if (mouse.button === Qt.RightButton)
            Notifs.dnd = !Notifs.dnd;
        else
            Notifs.centerOpen = !Notifs.centerOpen;
    }

    Icon {
        name: Notifs.dnd ? "notifications_off" : Notifs.count > 0 ? "notifications_unread" : "notifications"
        color: root.fg
    }
    Label {
        visible: Notifs.count > 0
        text: Notifs.count
        color: root.fg
    }
}
