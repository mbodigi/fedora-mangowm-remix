pragma Singleton
// CPU and memory usage, sampled from /proc every 2 seconds.
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real cpu: 0      // percent
    property real mem: 0      // percent
    property real memUsedGiB: 0

    property var lastIdle: 0
    property var lastTotal: 0

    Process {
        id: reader
        command: ["cat", "/proc/stat", "/proc/meminfo"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n");
                const f = lines[0].trim().split(/\s+/).slice(1).map(Number);
                const idle = f[3] + f[4];
                const total = f.reduce((a, b) => a + b, 0);
                if (root.lastTotal > 0 && total > root.lastTotal)
                    root.cpu = 100 * (1 - (idle - root.lastIdle) / (total - root.lastTotal));
                root.lastIdle = idle;
                root.lastTotal = total;

                const kb = key => Number((lines.find(l => l.startsWith(key + ":")) ?? "0 0").split(/\s+/)[1]);
                const total_kb = kb("MemTotal");
                const used_kb = total_kb - kb("MemAvailable");
                root.mem = total_kb ? 100 * used_kb / total_kb : 0;
                root.memUsedGiB = used_kb / 1048576;
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: reader.running = true
    }
}
