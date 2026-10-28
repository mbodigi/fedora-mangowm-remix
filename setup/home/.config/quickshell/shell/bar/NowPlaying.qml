// Now playing. Click: play/pause, right click: next, middle click: previous.
import QtQuick
import "../services"

Chip {
    id: root

    readonly property var player: Media.player

    visible: Settings.get("showMedia") && player !== null && (player.trackTitle ?? "") !== ""

    onClicked: mouse => {
        if (mouse.button === Qt.RightButton) Media.next();
        else if (mouse.button === Qt.MiddleButton) Media.previous();
        else Media.playPause();
    }

    Icon { name: root.player && root.player.isPlaying ? "pause" : "play_arrow" }
    Label {
        width: Math.min(implicitWidth, 220)
        text: root.player ? (root.player.trackArtist ? root.player.trackArtist + " — " : "") + root.player.trackTitle : ""
    }
}
