// A Material Symbols glyph, e.g. Icon { name: "battery_full" }
import QtQuick
import "../services"

Text {
    property string name
    property bool filled: false

    text: name
    color: Theme.text
    font.family: Theme.iconFont
    font.pixelSize: Theme.iconSize
    font.variableAxes: ({ "FILL": filled ? 1 : 0, "wght": 400, "opsz": 20 })
    verticalAlignment: Text.AlignVCenter
}
