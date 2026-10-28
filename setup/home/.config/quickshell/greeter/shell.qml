// Login screen for greetd, styled like our shell's lock screen.
// Installed to /usr/local/share/shell-greeter and run by greetd as the "greeter" user inside a bare mango.
// Wallpaper + colors are synced by the user's shell into /var/cache/shell-greeter.
// Outside greetd (Greetd.available is false) it runs as a preview and never logs anyone in.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Greetd

ShellRoot {
    id: root

    readonly property string dataDir: Quickshell.env("SHELL_GREETER_DATA") || "/var/cache/shell-greeter"
    readonly property string stateFile: (Quickshell.env("HOME") || "/var/lib/greeter") + "/last-user"

    property var pal: ({})
    function c(name, fallback) { return pal[name] ?? fallback; }
    readonly property color surface: c("surface", "#131313")
    readonly property color surfaceContainer: c("surface_container", "#1f1f1f")
    readonly property color surfaceHigh: c("surface_container_high", "#2a2a2a")
    readonly property color text: c("on_surface", "#e2e2e2")
    readonly property color textMuted: c("on_surface_variant", "#c6c6c6")
    readonly property color outline: c("outline", "#919191")
    readonly property color errorColor: c("error", "#ffb4ab")

    property var users: []            // login users from /etc/passwd
    property int userIndex: 0
    readonly property string user: users[userIndex] ?? ""
    property var sessions: []         // [{name, exec}] from /usr/share/wayland-sessions
    property int sessionIndex: 0
    property string password: ""
    property string status: ""
    property bool busy: false

    function login() {
        if (busy || !user || password === "") return;
        status = "";
        if (!Greetd.available) { status = "Preview mode — not running under greetd"; password = ""; return; }
        busy = true;
        Greetd.createSession(user);
    }

    function fail(message) {
        busy = false;
        password = "";
        status = message;
        Greetd.cancelSession();
    }

    FontLoader { id: icons; source: Qt.resolvedUrl("MaterialSymbolsRounded.ttf") }

    FileView {
        id: colorsFile
        path: root.dataDir + "/colors.json"
        onLoaded: { try { const c = JSON.parse(colorsFile.text()).colors; root.pal = c.dark ?? c; } catch (e) {} }
    }

    FileView {
        id: lastUser
        path: root.stateFile
        onLoaded: root.pickUser(lastUser.text().trim())
    }

    function pickUser(name) {
        const i = users.indexOf(name);
        if (i >= 0) userIndex = i;
    }

    Process {
        command: ["sh", "-c", "awk -F: '$3 >= 1000 && $3 < 60000 && $7 !~ /(nologin|false)$/ {print $1}' /etc/passwd"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.users = text.split("\n").filter(u => u);
                root.pickUser(lastUser.text().trim());
            }
        }
    }

    Process {
        command: ["sh", "-c", "for f in /usr/share/wayland-sessions/*.desktop; do n=$(sed -n 's/^Name=//p' \"$f\" | head -1); e=$(sed -n 's/^Exec=//p' \"$f\" | head -1); printf '%s\\t%s\\n' \"$n\" \"$e\"; done"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.sessions = text.split("\n").filter(l => l.includes("\t")).map(l => ({ name: l.split("\t")[0], exec: l.split("\t")[1] }))
        }
    }

    Connections {
        target: Greetd
        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (responseRequired) Greetd.respond(root.password);
            else if (error) root.status = message;
        }
        function onAuthFailure(message) { root.fail("Wrong password"); }
        function onError(error) { root.fail("Login error: " + error); }
        function onReadyToLaunch() {
            lastUser.setText(root.user);
            const session = root.sessions[root.sessionIndex];
            Greetd.launch((session ? session.exec : "mango").split(" "), [], true);
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            color: root.surface

            Image {
                anchors.fill: parent
                source: "file://" + root.dataDir + "/wallpaper"
                fillMode: Image.PreserveAspectCrop
                sourceSize.width: win.modelData.width
                sourceSize.height: win.modelData.height
                asynchronous: true
                cache: false
            }
            Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.55) }

            SystemClock { id: clock; precision: SystemClock.Seconds }

            component T: Text {
                color: root.text
                font.family: "JetBrains Mono"
                font.pixelSize: 14
                verticalAlignment: Text.AlignVCenter
            }
            component I: Text {
                color: root.text
                font.family: icons.name
                font.pixelSize: 20
                verticalAlignment: Text.AlignVCenter
            }

            Column {
                anchors.centerIn: parent
                spacing: 16

                T {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "h:mm")
                    font.pixelSize: 110
                    font.weight: Font.Bold
                }
                T {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "dddd, MMMM d")
                    font.pixelSize: 20
                    color: root.textMuted
                }

                Item { width: 1; height: 24 }

                // user picker (click to switch when there is more than one)
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: userRow.implicitWidth + 32
                    height: 40
                    radius: 20
                    color: userArea.containsMouse && root.users.length > 1 ? root.surfaceHigh : "transparent"
                    Row {
                        id: userRow
                        anchors.centerIn: parent
                        spacing: 8
                        I { text: "account_circle"; font.pixelSize: 26 }
                        T { text: root.user; font.pixelSize: 18; font.weight: Font.DemiBold }
                        I { visible: root.users.length > 1; text: "unfold_more"; color: root.textMuted }
                    }
                    MouseArea {
                        id: userArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: if (root.users.length > 1) root.userIndex = (root.userIndex + 1) % root.users.length
                    }
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 340
                    height: 52
                    radius: 26
                    color: root.surfaceContainer
                    border.width: 1
                    border.color: root.status !== "" ? root.errorColor : root.surfaceHigh

                    I {
                        id: lockIcon
                        anchors { left: parent.left; leftMargin: 18; verticalCenter: parent.verticalCenter }
                        text: root.busy ? "hourglass_top" : "lock"
                        color: root.textMuted
                    }
                    TextInput {
                        id: input
                        anchors { left: lockIcon.right; right: parent.right; leftMargin: 12; rightMargin: 18; verticalCenter: parent.verticalCenter }
                        color: root.text
                        font.family: "JetBrains Mono"
                        font.pixelSize: 18
                        echoMode: TextInput.Password
                        passwordCharacter: "●"
                        enabled: !root.busy
                        focus: true
                        text: root.password
                        onTextChanged: root.password = text
                        onAccepted: root.login()
                        Component.onCompleted: forceActiveFocus()
                        T {
                            visible: input.text === ""
                            text: "Password"
                            color: root.outline
                            font.pixelSize: 16
                        }
                    }
                }

                T {
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: 20
                    text: root.status
                    color: root.errorColor
                }
            }

            // bottom bar: session on the left, power on the right
            Row {
                anchors { left: parent.left; bottom: parent.bottom; margins: 24 }
                spacing: 8
                I { text: "desktop_windows"; color: root.textMuted }
                T {
                    text: root.sessions[root.sessionIndex]?.name ?? "Mango"
                    color: root.textMuted
                    MouseArea {
                        anchors.fill: parent
                        onClicked: if (root.sessions.length > 1) root.sessionIndex = (root.sessionIndex + 1) % root.sessions.length
                    }
                }
            }

            Row {
                anchors { right: parent.right; bottom: parent.bottom; margins: 24 }
                spacing: 12
                Repeater {
                    model: [{ icon: "restart_alt", cmd: "reboot" }, { icon: "power_settings_new", cmd: "poweroff" }]
                    Rectangle {
                        required property var modelData
                        width: 44
                        height: 44
                        radius: 22
                        color: power.containsMouse ? root.surfaceHigh : root.surfaceContainer
                        I { anchors.centerIn: parent; text: parent.modelData.icon }
                        MouseArea {
                            id: power
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: if (Greetd.available) Quickshell.execDetached(["systemctl", parent.modelData.cmd])
                        }
                    }
                }
            }

            MouseArea { anchors.fill: parent; z: -1; onClicked: input.forceActiveFocus() }
        }
    }
}
