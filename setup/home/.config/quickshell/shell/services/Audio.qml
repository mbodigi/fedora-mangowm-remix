pragma Singleton
// Default speaker and microphone via PipeWire, with step helpers for the media keys,
// and the lists of output/input devices to switch between.
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property bool micMuted: source?.audio?.muted ?? false

    // hardware/Bluetooth devices (not app streams)
    readonly property var outputs: Pipewire.nodes.values.filter(n => n.audio && n.isSink && !n.isStream)
    readonly property var inputs: Pipewire.nodes.values.filter(n => n.audio && !n.isSink && !n.isStream)

    function label(node) { return node ? (node.description || node.nickname || node.name) : ""; }
    function setOutput(node) { Pipewire.preferredDefaultAudioSink = node; }
    function setInput(node) { Pipewire.preferredDefaultAudioSource = node; }

    signal changed(string what)   // "volume" | "mic", for the OSD

    function step(delta) {
        if (!sink?.audio) return;
        sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(1, Math.round((sink.audio.volume + delta) * 100) / 100));
        changed("volume");
    }

    function setVolume(v) {
        if (!sink?.audio) return;
        sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(1, v));
    }

    function toggleMute() {
        if (!sink?.audio) return;
        sink.audio.muted = !sink.audio.muted;
        changed("volume");
    }

    function toggleMic() {
        if (!source?.audio) return;
        source.audio.muted = !source.audio.muted;
        changed("mic");
    }

    PwObjectTracker {
        objects: [root.sink, root.source]
    }
}
