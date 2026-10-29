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

    // fingerprint (assets/pam/lock-fingerprint) runs alongside the password check and unlocks on a match
    property bool fpAvailable: false   // the sensor answered with "place your finger": show the icon
    property bool fpUnavailable: false // a run gave up at once (no sensor, fprintd busy, just resumed)
    // fingerprint first: the password box appears on typing, a click, a no-match, or without a sensor
    property bool showPassword: false
    readonly property bool passwordShown: showPassword || fpUnavailable
    property bool fpNoMatch: false     // last touch didn't match: icon turns red for a moment
    property double fpStartedAt: 0

    function lock() {
        password = "";
        status = "";
        showPassword = false;
        locked = true;
        startFingerprint();
    }

    function unlock() {
        locked = false;
        password = "";
        status = "";
        checking = false;
        fpRetry.stop();
        if (fpPam.active) fpPam.abort();
        if (pam.active) pam.abort();
    }

    function startFingerprint() {
        if (!locked || fpPam.active) return;
        fpStartedAt = Date.now();
        fpPam.start();
    }

    // run ended without unlocking: listen again; if it gave up at once there's no usable sensor
    // (none enrolled, fprintd busy, just resumed): hide the icon and try again later
    function fingerprintEnded() {
        if (!locked) return;
        const quick = Date.now() - fpStartedAt < 2000;
        if (quick) {
            fpAvailable = false;
            fpUnavailable = true;
        }
        fpRetry.interval = quick ? 10000 : 500;
        fpRetry.restart();
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

    Timer {
        id: fpRetry
        onTriggered: root.startFingerprint()
    }

    Timer {
        id: fpNoMatchFlash
        interval: 1500
        onTriggered: root.fpNoMatch = false
    }

    PamContext {
        id: fpPam
        configDirectory: Quickshell.shellDir + "/assets/pam"
        config: "lock-fingerprint"

        onPamMessage: {
            if (responseRequired) {
                respond("");    // pam_fprintd never asks; don't hang if something else does
            } else if (messageIsError) {
                root.fpNoMatch = true;
                root.showPassword = true;
                fpNoMatchFlash.restart();
            } else {
                root.fpAvailable = true;
                root.fpUnavailable = false;
            }
        }
        onCompleted: result => {
            if (result === PamResult.Success) root.unlock();
            else root.fingerprintEnded();
        }
        onError: root.fingerprintEnded()
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

                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 340
                    height: 52

                    // fingerprint first (red for a moment after a touch that didn't match)
                    Icon {
                        anchors.centerIn: parent
                        visible: !root.passwordShown
                        name: "fingerprint"
                        font.pixelSize: 64
                        color: root.fpNoMatch ? Theme.error : Theme.text
                    }

                    // the password box stays focused while hidden, so the first key typed brings it up
                    Rectangle {
                        anchors.fill: parent
                        opacity: root.passwordShown ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 150 } }
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
                            onTextChanged: {
                                root.password = text;
                                if (text !== "") root.showPassword = true;
                            }
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
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.status
                    color: Theme.error
                    height: 20
                }

                // touch the sensor to unlock (red for a moment after a touch that didn't match)
                Icon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: root.fpAvailable && root.passwordShown
                    name: "fingerprint"
                    font.pixelSize: 40
                    color: root.fpNoMatch ? Theme.error : Theme.textMuted
                }
            }

            // keep keyboard focus on the password box whatever gets clicked
            MouseArea {
                anchors.fill: parent
                z: -1
                onClicked: {
                    root.showPassword = true;
                    input.forceActiveFocus();
                }
            }
        }
    }
}
