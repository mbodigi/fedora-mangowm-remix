pragma Singleton
// CPU, memory and network usage, sampled from /proc every 2 seconds.
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real cpu: 0      // percent
    property real mem: 0      // percent
    property real memUsedGiB: 0
    property real rxRate: 0   // bytes/s down, all real interfaces together
    property real txRate: 0   // bytes/s up

    // megabits per second, like internet plans and speed tests: "56", "2.3", "0.4"
    function mbps(bytesPerSec) {
        const m = bytesPerSec * 8 / 1e6;
        return m >= 10 ? Math.round(m).toString() : m.toFixed(1);
    }

    property var lastIdle: 0
    property var lastTotal: 0
    property var lastRx: -1
    property var lastTx: 0
    property var lastNetTime: 0

    Process {
        id: reader
        command: ["cat", "/proc/stat", "/proc/meminfo", "/proc/net/dev"]
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

                // network: real interfaces only (not loopback, VM bridges or container veths,
                // whose traffic would be counted twice)
                let rx = 0, tx = 0;
                for (const l of lines) {
                    const m = l.match(/^\s*([^:\s]+):\s*(\d+)(?:\s+\d+){7}\s+(\d+)/);
                    if (!m || /^(lo|virbr|vnet|veth|docker|br-|podman|tap)/.test(m[1])) continue;
                    rx += Number(m[2]);
                    tx += Number(m[3]);
                }
                const now = Date.now();
                if (root.lastRx >= 0 && now > root.lastNetTime) {
                    const dt = (now - root.lastNetTime) / 1000;
                    root.rxRate = Math.max(0, (rx - root.lastRx) / dt);
                    root.txRate = Math.max(0, (tx - root.lastTx) / dt);
                }
                root.lastRx = rx;
                root.lastTx = tx;
                root.lastNetTime = now;
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
