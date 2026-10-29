// Control center: volume/brightness sliders, quick toggles, Wi-Fi, Bluetooth and sound-device lists. (Coffee lives on the bar only.)
// Toggle with: qs -c shell ipc call control toggle
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.UPower
import "../services"
import "../bar"

PanelWindow {
    id: root

    readonly property bool open: Panels.control
    property string section: ""     // "", "wifi", "bluetooth" or "sound"
    property var askPassword: null  // Wi-Fi network waiting for a password

    readonly property var bt: Bluetooth.defaultAdapter

    visible: open
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Normal
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    WlrLayershell.namespace: "shell-control-center"

    onOpenChanged: {
        if (open) {
            Brightness.refresh();
            Notifs.centerOpen = false;
        } else {
            section = "";
            askPassword = null;
        }
        Net.scan(open && section === "wifi");
        setDiscovering(open && section === "bluetooth");
    }
    onSectionChanged: {
        Net.scan(open && section === "wifi");
        setDiscovering(open && section === "bluetooth");
    }

    // Bluetooth scans only briefly: this laptop's Intel card shares one radio between Wi-Fi and
    // Bluetooth, and a scan that keeps running breaks up connected audio devices (and makes new
    // connections fail). Scan for 15 s when the list opens; stop before connecting or pairing.
    function setDiscovering(on) {
        if (!bt) return;
        bt.discovering = on;
        if (on) btScanStop.restart(); else btScanStop.stop();
    }
    Timer { id: btScanStop; interval: 15000; onTriggered: if (root.bt) root.bt.discovering = false }

    IpcHandler {
        target: "control"
        function toggle(): void { Panels.control = !Panels.control; }
        function openSection(section: string): void { Panels.control = true; root.section = section; }
    }

    function profileName(p) {
        return p === PowerProfile.PowerSaver ? "Power saver" : p === PowerProfile.Performance ? "Performance" : "Balanced";
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Panels.control = false
    }

    Rectangle {
        id: panel
        anchors { top: parent.top; right: parent.right; topMargin: 6; rightMargin: 8 }
        width: 420
        height: body.implicitHeight + 28
        radius: 22
        color: Theme.surfaceContainer
        focus: true
        Keys.onEscapePressed: Panels.control = false

        MouseArea { anchors.fill: parent }   // swallow clicks inside

        ColumnLayout {
            id: body
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
            spacing: 10

            // sliders
            // volume: click the speaker for the output/input drop-down, right-click it to mute
            Slider {
                Layout.fillWidth: true
                icon: Audio.muted ? "volume_off" : "volume_up"
                value: Audio.muted ? 0 : Audio.volume
                expandable: true
                expanded: root.section === "sound"
                onMoved: v => Audio.setVolume(v)
                onIconClicked: root.section = root.section === "sound" ? "" : "sound"
                onIconRightClicked: Audio.toggleMute()
            }
            // sound drop-down: pick the output (speakers, headphones, HDMI, Bluetooth) and the input
            ColumnLayout {
                Layout.fillWidth: true
                visible: root.section === "sound"
                spacing: 4

                Label { text: "Output"; color: Theme.textMuted; font.pixelSize: 12 }
                Repeater {
                    model: Audio.outputs
                    ListRow {
                        required property var modelData
                        Layout.fillWidth: true
                        icon: /bluez/i.test(modelData.name) ? "headphones" : /hdmi|displayport/i.test(modelData.name) ? "tv" : "speaker"
                        title: Audio.label(modelData)
                        detail: modelData === Audio.sink ? "In use" : ""
                        highlighted: modelData === Audio.sink
                        onClicked: Audio.setOutput(modelData)
                    }
                }

                Label { text: "Input"; color: Theme.textMuted; font.pixelSize: 12; Layout.topMargin: 6 }
                Repeater {
                    model: Audio.inputs
                    ListRow {
                        required property var modelData
                        Layout.fillWidth: true
                        icon: "mic"
                        title: Audio.label(modelData)
                        detail: modelData === Audio.source ? "In use" : ""
                        highlighted: modelData === Audio.source
                        onClicked: Audio.setInput(modelData)
                    }
                }
            }

            Slider {
                Layout.fillWidth: true
                icon: "brightness_6"
                value: Brightness.level
                onMoved: v => Brightness.set(v)
            }

            // toggle tiles
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 8
                rowSpacing: 8

                Tile {
                    Layout.fillWidth: true
                    icon: Net.icon()
                    title: "Wi-Fi"
                    subtitle: Net.wired ? "Ethernet" : !Net.enabled ? "Off" : Net.active ? Net.active.name : "Not connected"
                    active: Net.enabled
                    expandable: true
                    expanded: root.section === "wifi"
                    onToggled: Net.setEnabled(!Net.enabled)
                    onExpandClicked: root.section = root.section === "wifi" ? "" : "wifi"
                }
                Tile {
                    Layout.fillWidth: true
                    icon: root.bt && root.bt.enabled ? "bluetooth" : "bluetooth_disabled"
                    title: "Bluetooth"
                    subtitle: {
                        if (!root.bt) return "Unavailable";
                        if (!root.bt.enabled) return "Off";
                        const c = root.bt.devices.values.filter(d => d.connected);
                        return c.length ? c.map(d => d.name).join(", ") : "On";
                    }
                    active: root.bt ? root.bt.enabled : false
                    expandable: root.bt !== null
                    expanded: root.section === "bluetooth"
                    onToggled: if (root.bt) root.bt.enabled = !root.bt.enabled
                    onExpandClicked: root.section = root.section === "bluetooth" ? "" : "bluetooth"
                }
                Tile {
                    Layout.fillWidth: true
                    icon: Notifs.dnd ? "notifications_off" : "notifications"
                    title: "Do not disturb"
                    subtitle: Notifs.dnd ? "On" : "Off"
                    active: Notifs.dnd
                    onToggled: Notifs.dnd = !Notifs.dnd
                }
                Tile {
                    Layout.fillWidth: true
                    icon: PowerProfiles.profile === PowerProfile.PowerSaver ? "energy_savings_leaf"
                        : PowerProfiles.profile === PowerProfile.Performance ? "speed" : "balance"
                    title: "Power mode"
                    subtitle: root.profileName(PowerProfiles.profile)
                    active: PowerProfiles.profile !== PowerProfile.Balanced
                    onToggled: {
                        const order = [PowerProfile.PowerSaver, PowerProfile.Balanced];
                        if (PowerProfiles.hasPerformanceProfile) order.push(PowerProfile.Performance);
                        PowerProfiles.profile = order[(order.indexOf(PowerProfiles.profile) + 1) % order.length];
                    }
                }
                Tile {
                    Layout.fillWidth: true
                    icon: Audio.micMuted ? "mic_off" : "mic"
                    title: "Microphone"
                    subtitle: Audio.micMuted ? "Muted" : "On"
                    active: !Audio.micMuted
                    onToggled: Audio.toggleMic()
                }
            }

            // Wi-Fi networks
            ColumnLayout {
                Layout.fillWidth: true
                visible: root.section === "wifi"
                spacing: 4

                Label {
                    text: Net.enabled ? "Wi-Fi networks" : "Wi-Fi is off"
                    color: Theme.textMuted
                    font.pixelSize: 12
                }

                Repeater {
                    model: Net.enabled ? Net.networks.slice(0, 10) : []

                    ListRow {
                        required property var modelData
                        Layout.fillWidth: true
                        icon: modelData.signalStrength > 0.66 ? "network_wifi" : modelData.signalStrength > 0.33 ? "network_wifi_2_bar" : "network_wifi_1_bar"
                        title: modelData.name
                        detail: modelData.connected ? "Connected"
                              : modelData.state === ConnectionState.Connecting ? "Connecting…"
                              : modelData.security !== WifiSecurityType.Open && !modelData.known ? "Secured" : modelData.known ? "Saved" : "Open"
                        highlighted: modelData.connected
                        trailingIcon: modelData.security !== WifiSecurityType.Open ? "lock" : ""
                        onClicked: {
                            if (modelData.connected) modelData.disconnect();
                            else if (modelData.known || modelData.security === WifiSecurityType.Open) modelData.connect();
                            else root.askPassword = modelData;
                        }
                    }
                }

                // password prompt
                Rectangle {
                    Layout.fillWidth: true
                    visible: root.askPassword !== null
                    height: 44
                    radius: 12
                    color: Theme.surface

                    TextInput {
                        id: psk
                        anchors { left: parent.left; right: join.left; leftMargin: 12; rightMargin: 8; verticalCenter: parent.verticalCenter }
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: 14
                        echoMode: TextInput.Password
                        clip: true
                        onVisibleChanged: if (visible) { text = ""; forceActiveFocus(); }
                        onAccepted: join.submit()

                        Label {
                            visible: psk.text === ""
                            text: root.askPassword ? "Password for " + root.askPassword.name : ""
                            color: Theme.outline
                        }
                    }
                    Chip {
                        id: join
                        anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                        function submit() {
                            if (root.askPassword && psk.text.length >= 8) {
                                root.askPassword.connectWithPsk(psk.text);
                                root.askPassword = null;
                            }
                        }
                        onClicked: submit()
                        Label { text: "Connect" }
                    }
                }
            }

            // Bluetooth devices
            ColumnLayout {
                Layout.fillWidth: true
                visible: root.section === "bluetooth"
                spacing: 4

                Label {
                    text: root.bt && root.bt.enabled ? (root.bt.discovering ? "Bluetooth devices (searching…)" : "Bluetooth devices") : "Bluetooth is off"
                    color: Theme.textMuted
                    font.pixelSize: 12
                }

                Repeater {
                    model: root.bt && root.bt.enabled
                        ? root.bt.devices.values.filter(d => d.name && !/^([0-9a-f]{2}[-:]){5}[0-9a-f]{2}$/i.test(d.name)).sort((a, b) => b.connected - a.connected || b.paired - a.paired).slice(0, 10)
                        : []

                    ListRow {
                        required property var modelData
                        Layout.fillWidth: true
                        icon: modelData.icon && modelData.icon.includes("audio") ? "headphones"
                            : modelData.icon && modelData.icon.includes("input") ? "keyboard" : "bluetooth"
                        title: modelData.name
                        detail: modelData.state === BluetoothDeviceState.Connecting ? "Connecting…"
                              : modelData.connected ? "Connected" + (modelData.batteryAvailable ? " · " + Math.round(modelData.battery * 100) + "%" : "")
                              : modelData.paired ? "Paired" : "Available"
                        highlighted: modelData.connected
                        onClicked: {
                            root.setDiscovering(false);
                            if (modelData.connected) modelData.disconnect();
                            else if (modelData.paired) modelData.connect();
                            else { modelData.trusted = true; modelData.pair(); }
                        }
                        // a newly paired device connects right away
                        Connections {
                            target: modelData
                            function onPairedChanged() { if (modelData.paired && !modelData.connected) modelData.connect(); }
                        }
                    }
                }
            }
        }
    }
}
