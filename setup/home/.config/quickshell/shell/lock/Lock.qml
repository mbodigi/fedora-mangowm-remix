// Lock screen (ext-session-lock + PAM). Lock with: qs -c shell ipc call lock lock
// testLock locks and unlocks itself after 10 s, for checking the look without a password.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import "../services"
import "../bar"

Scope {
    id: root

    property bool locked: false
    property string password: ""
    property string status: ""      // message under the password box
    property bool checking: false

    function lock() {
        password = "";
        status = "";
        locked = true;
    }

    function unlock() {
        locked = false;
        password = "";
        status = "";
        checking = false;
    }

    function submit() {
        if (checking || password === "") return;
        checking = true;
        status = "";
        pam.start();
    }

    Connections {
        target: LockState
        function onLockRequested() { root.lock(); }
    }

    Binding { target: LockState; property: "locked"; value: root.locked }

    IpcHandler {
        target: "lock"
        function lock(): void { root.lock(); }
        function testLock(): void { root.lock(); testTimer.start(); }
        function isLocked(): bool { return root.locked; }
    }

    Timer {
        id: testTimer
        interval: 10000
        onTriggered: root.unlock()
    }

    PamContext {
        id: pam
        configDirectory: Quickshell.shellDir + "/assets/pam"
        config: "lock"

        onPamMessage: {
            if (responseRequired)
                respond(root.password);
            else if (messageIsError)
                root.status = message;
        }
        onCompleted: result => {
            if (result === PamResult.Success) {
                root.unlock();
            } else {
                root.checking = false;
                root.password = "";
                root.status = result === PamResult.MaxTries ? "Too many attempts, wait a moment" : "Wrong password";
            }
        }
        onError: {
            root.checking = false;
            root.status = "Could not check the password";
        }
    }

    WlSessionLock {
        locked: root.locked

        WlSessionLockSurface {
            id: surface
            color: Theme.surface

            SystemClock {
                id: clock
                precision: SystemClock.Seconds
            }

            Column {
                anchors.centerIn: parent
                spacing: 18

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "h:mm")
                    font.pixelSize: 110
                    font.weight: Font.Bold
                }
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "dddd, MMMM d")
                    font.pixelSize: 20
                    color: Theme.textMuted
                }

                Item { width: 1; height: 30 }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 340
                    height: 52
                    radius: 26
                    color: Theme.surfaceContainer
                    border.width: 1
                    border.color: root.status !== "" ? Theme.error : Theme.surfaceHigh

                    Icon {
                        id: lockIcon
                        anchors { left: parent.left; leftMargin: 18; verticalCenter: parent.verticalCenter }
                        name: root.checking ? "hourglass_top" : "lock"
                        color: Theme.textMuted
                    }

                    TextInput {
                        id: input
                        anchors { left: lockIcon.right; right: parent.right; leftMargin: 12; rightMargin: 18; verticalCenter: parent.verticalCenter }
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: 18
                        echoMode: TextInput.Password
                        passwordCharacter: "●"
                        enabled: !root.checking
                        focus: true
                        text: root.password
                        onTextChanged: root.password = text
                        onAccepted: root.submit()
                        Keys.onEscapePressed: root.password = ""
                        Component.onCompleted: forceActiveFocus()

                        Label {
                            visible: input.text === ""
                            text: "Password"
                            color: Theme.outline
                            font.pixelSize: 16
                        }
                    }
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.status
                    color: Theme.error
                    height: 20
                }
            }

            // keep keyboard focus on the password box whatever gets clicked
            MouseArea {
                anchors.fill: parent
                z: -1
                onClicked: input.forceActiveFocus()
            }
        }
    }
}
