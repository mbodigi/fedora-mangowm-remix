pragma Singleton
// Wi-Fi state via NetworkManager (Quickshell.Networking).
import QtQuick
import Quickshell
import Quickshell.Networking

Singleton {
    id: root

    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wired: Networking.devices.values.find(d => d.type === DeviceType.Wired && d.connected) ?? null
    readonly property bool enabled: Networking.wifiEnabled
    readonly property var active: wifi ? wifi.networks.values.find(n => n.connected) ?? null : null
    readonly property var networks: wifi
        ? wifi.networks.values.filter(n => n.name).sort((a, b) => b.connected - a.connected || b.signalStrength - a.signalStrength)
        : []

    function setEnabled(on) { Networking.wifiEnabled = on; }
    function scan(on) { if (wifi) wifi.scannerEnabled = on; }

    function icon() {
        if (wired) return "lan";
        if (!enabled) return "wifi_off";
        if (!active) return "signal_wifi_0_bar";
        const s = active.signalStrength;
        return s > 0.75 ? "network_wifi" : s > 0.5 ? "network_wifi_3_bar" : s > 0.25 ? "network_wifi_2_bar" : "network_wifi_1_bar";
    }
}
