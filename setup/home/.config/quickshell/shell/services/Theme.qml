pragma Singleton
// Colors and fonts. Colors come from matugen (services/Wallpaper.qml regenerates them); fallbacks match the dark theme.
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var pal: ({})
    function c(name, fallback) { return pal[name] ?? fallback; }

    readonly property color surface: c("surface", "#131313")
    readonly property color surfaceContainer: c("surface_container", "#1f1f1f")
    readonly property color surfaceHigh: c("surface_container_high", "#2a2a2a")
    readonly property color text: c("on_surface", "#e2e2e2")
    readonly property color textMuted: c("on_surface_variant", "#c6c6c6")
    readonly property color outline: c("outline", "#919191")
    // accent is a fixed soft gray everywhere (GTK, Qt, mango and the dock use the same values)
    readonly property color primary: "#505050"          // highlight fill: active tile, selected tab, today
    readonly property color accentLine: "#8a8a8a"       // thin accents: slider/OSD fill, focus outlines
    readonly property color textOnPrimary: "#ffffff"
    readonly property color error: c("error", "#ffb4ab")
    readonly property color grayAccent: Qt.rgba(1, 1, 1, 0.26)   // flat bar: active tag / open panel

    readonly property string font: "JetBrains Mono"
    readonly property string iconFont: icons.name
    readonly property int fontSize: 13
    readonly property int iconSize: 18

    FontLoader {
        id: icons
        source: Qt.resolvedUrl("../assets/fonts/MaterialSymbolsRounded.ttf")
    }

    FileView {
        id: colorsFile
        path: Quickshell.env("HOME") + "/.local/state/shell/colors.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const colors = JSON.parse(colorsFile.text()).colors;
                root.pal = colors.dark ?? colors;
            } catch (e) {
                console.warn("Theme: could not parse palette:", e);
            }
        }
    }
}
