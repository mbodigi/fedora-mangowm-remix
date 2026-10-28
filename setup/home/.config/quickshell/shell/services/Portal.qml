pragma Singleton
// Captive portal (hotel/airport Wi-Fi login): NetworkManager's connectivity check reports "portal",
// we show a notification that opens the login page in the default browser.
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string state: "unknown"   // none | portal | limited | full | unknown
    readonly property bool portal: state === "portal"
    // plain http so the portal can redirect it
    readonly property string loginUrl: "http://neverssl.com"

    function openLogin() { Quickshell.execDetached(["xdg-open", root.loginUrl]); }

    function notify() {
        Quickshell.execDetached(["sh", "-c",
            'a=$(notify-send -a "Wi-Fi" -i network-wireless -u critical -A default=Log\\ in -A open=Log\\ in ' +
            '"Wi-Fi login required" "This network needs you to sign in. Click to open the login page.")\n' +
            '[ -n "$a" ] && xdg-open "$1"', "sh", root.loginUrl]);
    }

    onPortalChanged: if (portal) notify()

    // state at startup
    Process {
        command: ["nmcli", "-t", "-f", "CONNECTIVITY", "general"]
        running: true
        stdout: SplitParser { onRead: line => root.state = line.trim() }
    }

    // "Connectivity is now 'portal'" etc.
    Process {
        id: monitor
        command: ["setpriv", "--pdeathsig", "TERM", "--", "env", "LC_ALL=C", "nmcli", "monitor"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                const m = line.match(/Connectivity is now '(\w+)'/);
                if (m) root.state = m[1];
            }
        }
        onRunningChanged: if (!running) restartMonitor.start()
    }
    Timer { id: restartMonitor; interval: 2000; onTriggered: monitor.running = true }

    // while the login page is up, re-check often so we notice the login within seconds
    // (NetworkManager alone re-checks every 5 minutes; NextDNS switches back on "full")
    Timer {
        interval: 15000
        repeat: true
        running: root.portal
        onTriggered: Quickshell.execDetached(["nmcli", "networking", "connectivity", "check"])
    }

    IpcHandler {
        target: "portal"
        function login(): void { root.openLogin(); }
        function status(): string { return root.state; }
    }
}
