pragma Singleton
// Idle handling: lock, screen off, sleep. Coffee (and apps that inhibit idle, like video players) pause all of it.
// Timers come from Settings (defaults: battery lock 5 / screen off 6 / sleep 15 min; plugged in 10 / 11 / never).
// Also locks before the laptop sleeps (lid close, suspend) and on `loginctl lock-session`.
// Toggle coffee with: qs -c shell ipc call coffee toggle
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.UPower

Singleton {
    id: root

    property bool coffee: false

    readonly property bool onBattery: UPower.onBattery
    // seconds; 0 = never
    readonly property int lockAfter: Settings.get(onBattery ? "lockBattery" : "lockAC") * 60
    readonly property int screenOffAfter: Settings.get(onBattery ? "screenOffBattery" : "screenOffAC") * 60
    readonly property int sleepAfter: Settings.get(onBattery ? "sleepBattery" : "sleepAC") * 60

    function screen(on) {
        Quickshell.execDetached(["wlopm", on ? "--on" : "--off", "*"]);
    }

    IdleMonitor {
        enabled: !root.coffee && root.lockAfter > 0
        respectInhibitors: true
        timeout: root.lockAfter > 0 ? root.lockAfter : 86400
        onIsIdleChanged: if (isIdle) LockState.lock()
    }

    IdleMonitor {
        enabled: !root.coffee && root.screenOffAfter > 0
        respectInhibitors: true
        timeout: root.screenOffAfter > 0 ? root.screenOffAfter : 86400
        onIsIdleChanged: root.screen(!isIdle)
    }

    IdleMonitor {
        enabled: !root.coffee && root.sleepAfter > 0
        respectInhibitors: true
        timeout: root.sleepAfter > 0 ? root.sleepAfter : 86400
        onIsIdleChanged: if (isIdle) Quickshell.execDetached(["systemctl", "suspend"])
    }

    // Hold a "delay" sleep inhibitor so there is time to lock before the laptop sleeps.
    Process {
        id: sleepDelay
        // setpriv --pdeathsig: these helpers never write output, so make sure they exit with the shell
        command: ["setpriv", "--pdeathsig", "TERM", "--", "systemd-inhibit", "--what=sleep", "--mode=delay", "--who=shell",
                  "--why=Lock the screen before sleeping", "sleep", "infinity"]
        running: true
    }

    // logind signals: PrepareForSleep(true) before sleeping, PrepareForSleep(false) after waking,
    // Lock() from `loginctl lock-session`.
    Process {
        id: logind
        command: ["setpriv", "--pdeathsig", "TERM", "--", "gdbus", "monitor", "--system", "--dest", "org.freedesktop.login1"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                if (line.includes("PrepareForSleep (true,)")) {
                    LockState.lock();
                    releaseTimer.start();   // give the lock screen a moment to appear, then let sleep go ahead
                } else if (line.includes("PrepareForSleep (false,)")) {
                    root.screen(true);
                    sleepDelay.running = true;
                } else if (/\.Lock \(\)/.test(line)) {
                    LockState.lock();
                }
            }
        }
        onRunningChanged: if (!running) restartLogind.start()
    }
    Timer { id: restartLogind; interval: 2000; onTriggered: logind.running = true }

    Timer {
        id: releaseTimer
        interval: 800
        onTriggered: sleepDelay.running = false
    }

    IpcHandler {
        target: "coffee"
        function toggle(): void { root.coffee = !root.coffee; }
    }
}
