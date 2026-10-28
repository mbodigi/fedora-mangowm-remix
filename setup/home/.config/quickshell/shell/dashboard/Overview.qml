// Overview tab: clock, weather + forecast, month calendar, music player.
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services"
import "../bar"

GridLayout {
    columns: 2
    rowSpacing: 12
    columnSpacing: 12

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    // clock
    Card {
        Layout.preferredWidth: 440
        Layout.preferredHeight: 170
        Column {
            anchors.centerIn: parent
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(clock.date, "h:mm")
                font.pixelSize: 84
                font.weight: Font.Bold
            }
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(clock.date, "dddd, MMMM d")
                color: Theme.textMuted
                font.pixelSize: 16
            }
        }
    }

    // weather
    Card {
        Layout.fillWidth: true
        Layout.preferredHeight: 170

        Label {
            anchors.centerIn: parent
            visible: Weather.temp === ""
            text: "Loading weather…"
            color: Theme.outline
        }

        Row {
            visible: Weather.temp !== ""
            anchors { left: parent.left; top: parent.top; margins: 18 }
            spacing: 14
            Icon {
                name: Weather.icon(Weather.code, true)
                font.pixelSize: 56
            }
            Column {
                Label { text: Weather.temp; font.pixelSize: 36; font.weight: Font.Bold }
                Label { text: Weather.condition + " · feels " + Weather.feelsLike; color: Theme.textMuted }
                Label { text: Weather.location; color: Theme.outline; font.pixelSize: 11 }
            }
        }

        Row {
            visible: Weather.temp !== ""
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 14 }
            spacing: 8
            Repeater {
                model: Weather.days
                Rectangle {
                    required property var modelData
                    width: (parent.width - 16) / 3
                    height: 40
                    radius: 12
                    color: Theme.surfaceContainer
                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        Label {
                            text: Qt.formatDate(new Date(modelData.date + "T12:00:00"), "ddd")
                            font.weight: Font.DemiBold
                        }
                        Icon { name: Weather.icon(modelData.code, false); font.pixelSize: 18 }
                        Label { text: modelData.max + " / " + modelData.min; color: Theme.textMuted }
                    }
                }
            }
        }
    }

    // calendar
    Card {
        Layout.preferredWidth: 440
        Layout.fillHeight: true
        Calendar { anchors.fill: parent; anchors.margins: 14 }
    }

    // media
    Card {
        Layout.fillWidth: true
        Layout.fillHeight: true

        Label {
            anchors.centerIn: parent
            visible: !Media.player
            text: "Nothing playing"
            color: Theme.outline
        }

        Column {
            visible: Media.player !== null
            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 18 }
            spacing: 12

            Image {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 150
                height: 150
                fillMode: Image.PreserveAspectCrop
                source: Media.player?.trackArtUrl ?? ""
                visible: status === Image.Ready
                asynchronous: true
            }
            Label {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: Media.player?.trackTitle ?? ""
                font.pixelSize: 16
                font.weight: Font.DemiBold
            }
            Label {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: Media.player?.trackArtist ?? ""
                color: Theme.textMuted
            }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 10
                Chip { onClicked: Media.previous(); Icon { name: "skip_previous" } }
                Chip {
                    highlighted: true
                    onClicked: Media.playPause()
                    Icon {
                        name: Media.player?.isPlaying ? "pause" : "play_arrow"
                        color: Theme.textOnPrimary
                    }
                }
                Chip { onClicked: Media.next(); Icon { name: "skip_next" } }
            }
        }
    }
}
