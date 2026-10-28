pragma Singleton
// The "current" media player for the bar and the media keys: the one playing, else the first.
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null

    function playPause() { if (player?.canTogglePlaying) player.togglePlaying(); }
    function next() { if (player?.canGoNext) player.next(); }
    function previous() { if (player?.canGoPrevious) player.previous(); }
}
