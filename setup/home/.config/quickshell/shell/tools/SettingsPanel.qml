// Settings (Super+,): idle timers, bar options, color style. Changes save immediately.
// Toggle with: qs -c shell ipc call settings toggle
import QtQuick
import QtQuick.Layouts
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
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    WlrLayershell.namespace: "shell-settings"

    IpcHandler {
        target: "settings"
        function toggle(): void { root.visible = !root.visible; }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.visible = false
    }

    // "−  10 min  +" stepper bound to a Settings key (minutes, 0 = never)
    component Stepper: RowLayout {
        id: stepper
        property string label
        property string key
        property int step: 1
        readonly property int value: Settings.get(key)
        Layout.fillWidth: true

        Label { Layout.fillWidth: true; text: stepper.label }
        Chip { onClicked: Settings.set(stepper.key, Math.max(0, stepper.value - stepper.step)); Icon { name: "remove" } }
        Label {
            Layout.preferredWidth: 70
            horizontalAlignment: Text.AlignHCenter
            text: stepper.value === 0 ? "Never" : stepper.value + " min"
            font.weight: Font.DemiBold
        }
        Chip { onClicked: Settings.set(stepper.key, stepper.value + stepper.step); Icon { name: "add" } }
    }

    // on/off switch bound to a Settings key
    component Toggle: RowLayout {
        id: toggle
        property string label
        property string key
        readonly property bool on: Settings.get(key)
        Layout.fillWidth: true

        Label { Layout.fillWidth: true; text: toggle.label }
        Rectangle {
            width: 44
            height: 24
            radius: 12
            color: toggle.on ? Theme.primary : Theme.surfaceHigh
            Rectangle {
                x: toggle.on ? parent.width - width - 3 : 3
                anchors.verticalCenter: parent.verticalCenter
                width: 18
                height: 18
                radius: 9
                color: toggle.on ? Theme.textOnPrimary : Theme.textMuted
                Behavior on x { NumberAnimation { duration: 120 } }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Settings.set(toggle.key, !toggle.on)
            }
        }
    }

    component Heading: Label {
        Layout.topMargin: 8
        font.weight: Font.Bold
        color: Theme.text
    }

    Rectangle {
        anchors.centerIn: parent
        width: 520
        height: body.implicitHeight + 36
        radius: 24
        color: Theme.surface
        border.width: 1
        border.color: Theme.surfaceHigh
        focus: true
        Keys.onEscapePressed: root.visible = false

        MouseArea { anchors.fill: parent }   // swallow clicks inside

        ColumnLayout {
            id: body
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 }
            spacing: 8

            Label { text: "Settings"; font.pixelSize: 20; font.weight: Font.Bold }

            Heading { text: "On battery" }
            Stepper { label: "Lock after"; key: "lockBattery" }
            Stepper { label: "Screen off after"; key: "screenOffBattery" }
            Stepper { label: "Sleep after"; key: "sleepBattery"; step: 5 }

            Heading { text: "Plugged in" }
            Stepper { label: "Lock after"; key: "lockAC" }
            Stepper { label: "Screen off after"; key: "screenOffAC" }
            Stepper { label: "Sleep after"; key: "sleepAC"; step: 5 }

            Heading { text: "Top bar" }
            RowLayout {
                Layout.fillWidth: true
                Label { Layout.fillWidth: true; text: "Style" }
                Repeater {
                    model: [{ id: "mac", label: "Flat (mac)" }, { id: "pills", label: "Pills" }]
                    Chip {
                        id: style
                        required property var modelData
                        readonly property bool on: Settings.get("barStyle") === modelData.id
                        highlighted: on
                        onClicked: Settings.set("barStyle", modelData.id)
                        Label { text: style.modelData.label; color: style.on ? Theme.textOnPrimary : Theme.text }
                    }
                }
            }
            Toggle { label: "24-hour clock"; key: "clock24h" }
            Toggle { label: "Show CPU"; key: "showCpu" }
            Toggle { label: "Show RAM"; key: "showRam" }
            Toggle { label: "Show now playing"; key: "showMedia" }

            Heading { text: "Color style (from wallpaper)" }
            Flow {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: [
                        { id: "scheme-monochrome", label: "Monochrome" },
                        { id: "scheme-neutral", label: "Neutral" },
                        { id: "scheme-tonal-spot", label: "Tonal" },
                        { id: "scheme-vibrant", label: "Vibrant" },
                        { id: "scheme-expressive", label: "Expressive" },
                        { id: "scheme-content", label: "Content" }
                    ]
                    Chip {
                        id: scheme
                        required property var modelData
                        readonly property bool on: Settings.get("scheme") === modelData.id
                        highlighted: on
                        onClicked: { Settings.set("scheme", modelData.id); Wallpaper.regenerate(); }
                        Label { text: scheme.modelData.label; color: scheme.on ? Theme.textOnPrimary : Theme.text }
                    }
                }
            }

            Label {
                Layout.topMargin: 6
                text: "Wallpaper: Super+D → Wallpapers · Shortcuts: Super+Shift+/"
                color: Theme.outline
                font.pixelSize: 11
            }
        }
    }
}
