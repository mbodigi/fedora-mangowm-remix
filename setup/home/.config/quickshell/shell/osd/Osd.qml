// Volume / mic / brightness pop-up, shown near the bottom of the screen for 1.5 s after a key press.
// Keys call: qs -c shell ipc call osd <volumeUp|volumeDown|mute|micMute|brightnessUp|brightnessDown|playPause|next|previous>
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../services"
import "../bar"

PanelWindow {
    id: root

    property string kind: "volume"   // volume | mic | brightness

    visible: false
    color: "transparent"
    anchors.bottom: true
    margins.bottom: 90
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "shell-osd"
    implicitWidth: 300
    implicitHeight: 52

    function show(k) {
        kind = k;
        visible = true;
        hideTimer.restart();
    }

    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: root.visible = false
    }

    Connections {
        target: Audio
        function onChanged(what) { root.show(what); }
    }
    Connections {
        target: Brightness
        function onChanged() { root.show("brightness"); }
    }

    IpcHandler {
        target: "osd"
        function volumeUp(): void { Audio.step(0.05); }
        function volumeDown(): void { Audio.step(-0.05); }
        function mute(): void { Audio.toggleMute(); }
        function micMute(): void { Audio.toggleMic(); }
        function brightnessUp(): void { Brightness.step(0.05); }
        function brightnessDown(): void { Brightness.step(-0.05); }
        function playPause(): void { Media.playPause(); }
        function next(): void { Media.next(); }
        function previous(): void { Media.previous(); }
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.surface
        border.width: 1
        border.color: Theme.surfaceHigh

        readonly property real value: root.kind === "brightness" ? Brightness.level
                                    : root.kind === "mic" ? (Audio.micMuted ? 0 : 1)
                                    : (Audio.muted ? 0 : Audio.volume)

        Icon {
            id: icon
            anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
            font.pixelSize: 22
            name: root.kind === "brightness" ? "brightness_6"
                : root.kind === "mic" ? (Audio.micMuted ? "mic_off" : "mic")
                : Audio.muted ? "volume_off"
                : Audio.volume < 0.34 ? "volume_mute"
                : Audio.volume < 0.67 ? "volume_down" : "volume_up"
        }

        Rectangle {
            id: track
            anchors { left: icon.right; right: pct.left; leftMargin: 12; rightMargin: 12; verticalCenter: parent.verticalCenter }
            height: 6
            radius: 3
            color: Theme.surfaceHigh

            Rectangle {
                width: parent.width * Math.min(1, parent.parent.value)
                height: parent.height
                radius: 3
                color: Theme.accentLine
                Behavior on width { NumberAnimation { duration: 80 } }
            }
        }

        Label {
            id: pct
            anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
            width: 40
            horizontalAlignment: Text.AlignRight
            text: root.kind === "mic" ? (Audio.micMuted ? "Off" : "On") : Math.round(parent.value * 100) + "%"
        }
    }
}
