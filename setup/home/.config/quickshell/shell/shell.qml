// Our own shell (replacing DMS piece by piece). Run with: qs -c shell
import QtQuick
import Quickshell
import "bar"
import "launcher"
import "notifications"
import "osd"
import "control"
import "lock"
import "wallpaper"
import "dashboard"
import "tools"
import "security"
import "dock"
import "services"

ShellRoot {
    // singletons load lazily; start the ones that must run from login
    Component.onCompleted: [Idle.coffee, Clipboard.entries, BatteryAlerts.pct, Portal.state]

    Background {}

    Variants {
        model: Quickshell.screens
        Bar {}
    }

    Launcher {}
    ClipboardPanel {}
    PowerMenu {}
    Popups {}
    Center {}
    Osd {}
    ControlCenter {}
    Lock {}
    Dashboard {}
    Cheatsheet {}
    TaskManager {}
    SettingsPanel {}
    PolkitDialog {}
    Dock {}
}
