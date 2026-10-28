pragma Singleton
// User settings for the shell, saved to ~/.local/state/shell/settings.json. Edited in the Settings panel (Super+,).
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property var defaults: ({
        lockBattery: 5, screenOffBattery: 6, sleepBattery: 15,   // minutes, 0 = never
        lockAC: 10, screenOffAC: 11, sleepAC: 0,
        clock24h: false,
        showCpu: true, showRam: true, showMedia: true,
        scheme: "scheme-monochrome",
        barStyle: "pills",  // pills | mac
        dockPins: []        // desktop entry ids pinned to the dock, in order
    })
    property var values: defaults
    property bool loaded: false

    function get(key) { return values[key] ?? defaults[key]; }

    function set(key, value) {
        const v = Object.assign({}, values);
        v[key] = value;
        values = v;
        file.setText(JSON.stringify(values, null, 2));
    }

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.local/state/shell/settings.json"
        onLoaded: {
            try { root.values = Object.assign({}, root.defaults, JSON.parse(file.text())); } catch (e) {}
            root.loaded = true;
        }
        onLoadFailed: root.loaded = true
    }
}
