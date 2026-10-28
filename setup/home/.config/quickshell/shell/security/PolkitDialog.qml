// Polkit agent: the password dialog apps get when they need admin rights (Disks, software installs, pkexec).
// Only one agent per session can register; it takes over once DMS stops providing one.
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Polkit
import "../services"
import "../bar"

Scope {
    id: root

    property string error: ""
    readonly property var flow: agent.flow

    PolkitAgent { id: agent }

    Connections {
        target: root.flow
        enabled: root.flow !== null
        function onAuthenticationFailed() {
            root.error = "Wrong password, try again";
            input.text = "";
        }
        function onIsResponseRequiredChanged() {
            if (root.flow.isResponseRequired) input.forceActiveFocus();
        }
    }

    function submit() {
        if (!flow || !flow.isResponseRequired) return;
        error = "";
        flow.submit(input.text);
        input.text = "";
    }

    function cancel() {
        if (flow && !flow.isCompleted) flow.cancelAuthenticationRequest();
        error = "";
        input.text = "";
    }

    PanelWindow {
        visible: agent.isActive
        color: Qt.rgba(0, 0, 0, 0.5)
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        WlrLayershell.namespace: "shell-polkit"

        onVisibleChanged: if (visible) { root.error = ""; input.text = ""; input.forceActiveFocus(); }

        Rectangle {
            anchors.centerIn: parent
            width: 440
            height: column.implicitHeight + 40
            radius: 24
            color: Theme.surface
            border.width: 1
            border.color: Theme.surfaceHigh

            Column {
                id: column
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 20 }
                spacing: 12

                Row {
                    spacing: 12
                    IconImage {
                        implicitSize: 40
                        source: Quickshell.iconPath(root.flow?.iconName || "dialog-password", "dialog-password")
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        Label { text: "Authentication required"; font.pixelSize: 17; font.weight: Font.Bold }
                        Label {
                            text: "As " + (root.flow?.selectedIdentity?.displayName ?? root.flow?.selectedIdentity?.name ?? Quickshell.env("USER"))
                            color: Theme.textMuted
                        }
                    }
                }

                Label {
                    width: parent.width
                    text: root.flow?.message ?? ""
                    wrapMode: Text.Wrap
                    color: Theme.textMuted
                }

                Rectangle {
                    width: parent.width
                    height: 46
                    radius: 23
                    color: Theme.surfaceContainer
                    border.width: 1
                    border.color: root.error !== "" ? Theme.error : Theme.surfaceHigh

                    TextInput {
                        id: input
                        anchors { fill: parent; leftMargin: 18; rightMargin: 18 }
                        verticalAlignment: TextInput.AlignVCenter
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: 16
                        echoMode: root.flow?.responseVisible ? TextInput.Normal : TextInput.Password
                        passwordCharacter: "●"
                        focus: true
                        onAccepted: root.submit()
                        Keys.onEscapePressed: root.cancel()

                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: input.text === ""
                            text: (root.flow?.inputPrompt ?? "").replace(/[\s:]+$/, "") || "Password"
                            color: Theme.outline
                        }
                    }
                }

                Label {
                    visible: text !== ""
                    width: parent.width
                    text: root.error || (root.flow?.supplementaryMessage ?? "")
                    color: root.error || root.flow?.supplementaryIsError ? Theme.error : Theme.textMuted
                    wrapMode: Text.Wrap
                }

                Row {
                    anchors.right: parent.right
                    spacing: 8
                    Chip { onClicked: root.cancel(); Label { text: "Cancel" } }
                    Chip {
                        highlighted: true
                        onClicked: root.submit()
                        Label { text: "Authenticate"; color: Theme.textOnPrimary }
                    }
                }
            }
        }
    }
}
