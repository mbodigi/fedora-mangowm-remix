pragma Singleton
// Clipboard history via cliphist: watches the clipboard (text and images) and lists/restores entries.
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var entries: []   // [{id, text, isImage}]
    readonly property string thumbDir: Quickshell.env("XDG_RUNTIME_DIR") + "/shell-clip"

    function refresh() { lister.running = true; }

    function copy(entry) {
        Quickshell.execDetached(["sh", "-c", "cliphist decode \"$1\" | wl-copy", "sh", entry.id]);
    }

    function remove(entry) {
        Quickshell.execDetached(["sh", "-c", "printf '%s\\t%s\\n' \"$1\" \"$2\" | cliphist delete", "sh", entry.id, entry.text]);
        root.entries = root.entries.filter(e => e.id !== entry.id);
    }

    function wipe() {
        Quickshell.execDetached(["cliphist", "wipe"]);
        root.entries = [];
    }

    // keep recording while the shell runs (text, and images separately)
    Process {
        command: ["setpriv", "--pdeathsig", "TERM", "--", "wl-paste", "--watch", "cliphist", "store"]
        running: true
    }
    Process {
        command: ["setpriv", "--pdeathsig", "TERM", "--", "wl-paste", "--type", "image", "--watch", "cliphist", "store"]
        running: true
    }

    Process {
        id: lister
        // newest first; images are decoded into small files so the list can show them
        command: ["sh", "-c", "mkdir -p \"$1\"; cliphist list | head -n 100 | while IFS=\"$(printf '\\t')\" read -r id text; do " +
                  "case \"$text\" in '[[ binary data'*) [ -f \"$1/$id\" ] || cliphist decode \"$id\" > \"$1/$id\" 2>/dev/null;; esac; " +
                  "printf '%s\\t%s\\n' \"$id\" \"$text\"; done", "sh", root.thumbDir]
        stdout: StdioCollector {
            onStreamFinished: {
                root.entries = text.split("\n").filter(l => l.includes("\t")).map(l => {
                    const tab = l.indexOf("\t");
                    const body = l.slice(tab + 1);
                    return { id: l.slice(0, tab), text: body, isImage: body.startsWith("[[ binary data") };
                });
            }
        }
    }
}
