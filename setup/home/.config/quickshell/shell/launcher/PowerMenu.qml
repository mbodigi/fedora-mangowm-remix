// Power menu: Lock, Sleep, Log out, Restart, Shut down. Left/Right + Enter, or click.
// Log out / Restart / Shut down ask for a second press to confirm. Toggle with: qs -c shell ipc call power toggle
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../services"
import "../bar"

PanelWindow {
    id: root

    visible: false
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "shell-power"

    property int selected: 0
    property int confirming: -1

    readonly property var actions: [
        { icon: "lock", label: "Lock", confirm: false, run: () => LockState.lock() },
        { icon: "bedtime", label: "Sleep", confirm: false, run: () => Quickshell.execDetached(["systemctl", "suspend"]) },
        { icon: "logout", label: "Log out", confirm: true, run: () => Quickshell.execDetached(["mmsg", "dispatch", "quit"]) },
        { icon: "restart_alt", label: "Restart", confirm: true, run: () => Quickshell.execDetached(["systemctl", "reboot"]) },
        { icon: "power_settings_new", label: "Shut down", confirm: true, run: () => Quickshell.execDetached(["systemctl", "poweroff"]) }
    ]

    function open() {
        selected = 0;
        confirming = -1;
        visible = true;
        keys.forceActiveFocus();
    }

    function close() { visible = false; }

    function activate(i) {
        const a = actions[i];
        if (a.confirm && confirming !== i) {
            confirming = i;
            selected = i;
            return;
        }
        close();
        a.run();
    }

    IpcHandler {
        target: "power"
        function toggle(): void { root.visible ? root.close() : root.open(); }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.45)

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    Item {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) root.close();
            else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab) { root.selected = (root.selected + root.actions.length - 1) % root.actions.length; root.confirming = -1; }
            else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) { root.selected = (root.selected + 1) % root.actions.length; root.confirming = -1; }
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) root.activate(root.selected);
            else return;
            event.accepted = true;
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: 16

        Repeater {
            model: root.actions

            Rectangle {
                id: button
                required property var modelData
                required property int index
                readonly property bool isSelected: index === root.selected
                readonly property bool isConfirming: index === root.confirming

                width: 130
                height: 130
                radius: 28
                color: isConfirming ? Theme.error : isSelected ? Theme.primary : Theme.surfaceContainer
                border.width: 1
                border.color: Theme.surfaceHigh

                Column {
                    anchors.centerIn: parent
                    spacing: 10

                    Icon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        name: button.modelData.icon
                        font.pixelSize: 40
                        color: button.isSelected || button.isConfirming ? Theme.textOnPrimary : Theme.text
                    }
                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: button.isConfirming ? "Confirm?" : button.modelData.label
                        font.weight: Font.DemiBold
                        color: button.isSelected || button.isConfirming ? Theme.textOnPrimary : Theme.text
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: { root.selected = button.index; if (root.confirming !== button.index) root.confirming = -1; }
                    onClicked: root.activate(button.index)
                }
            }
        }
    }
}
