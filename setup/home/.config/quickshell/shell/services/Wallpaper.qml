pragma Singleton
// Current wallpaper. Setting one regenerates the color theme with matugen (shell, GTK, Qt, mango borders)
// and copies it to the login screen.
// Set with: qs -c shell ipc call wallpaper set /path/to/image.png
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string stateFile: Quickshell.env("HOME") + "/.local/state/shell/wallpaper"
    property string path: ""

    function regenerate() { set(root.path); }

    function set(newPath) {
        if (!newPath) return;
        root.path = newPath;
        file.setText(newPath);
        theme.command = ["matugen", "image", newPath,
                         "-c", Quickshell.shellDir + "/matugen/config.toml",
                         "-m", "dark", "-t", Settings.get("scheme"), "--source-color-index", "0", "-q"];
        theme.running = true;
        // keep the login screen's copy in sync
        Quickshell.execDetached(["cp", newPath, "/var/cache/shell-greeter/wallpaper"]);
    }

    FileView {
        id: file
        path: root.stateFile
        onLoaded: root.path = file.text().trim()
        onLoadFailed: root.path = ""
    }

    Process {
        id: theme
        onExited: (code, status) => {
            if (code !== 0)
                console.warn("Wallpaper: matugen exited with", code);
        }
    }

    IpcHandler {
        target: "wallpaper"
        function set(path: string): void { root.set(path); }
        function get(): string { return root.path; }
    }
}
