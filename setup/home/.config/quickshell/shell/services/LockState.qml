pragma Singleton
// Lets services (idle, sleep) ask the lock screen to lock, and see whether it is locked.
import QtQuick
import Quickshell

Singleton {
    property bool locked: false
    signal lockRequested()

    function lock() { lockRequested(); }
}
