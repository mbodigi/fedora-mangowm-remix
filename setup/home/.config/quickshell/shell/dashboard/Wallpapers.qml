// Wallpapers tab.
//  Mine:      images in ~/.local/share/wallpapers (and subfolders). Click to set.
//  Wallhaven: search wallhaven.cc (SFW only). Click to download into ~/.local/share/wallpapers and set; right click to just save.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../services"
import "../bar"

ColumnLayout {
    id: root

    property string source: "mine"      // mine | wallhaven
    property var mine: []
    readonly property string folder: Quickshell.env("HOME") + "/.local/share/wallpapers"   // hidden, out of ~/Pictures

    // wallhaven state
    property var results: []
    property int page: 1
    property int lastPage: 1
    property string sorting: "toplist"
    property string categories: "111"   // general / anime / people
    property bool loading: false
    property var downloading: ({})      // id -> true

    spacing: 12

    function refreshMine() { finder.running = true; }

    function search(reset) {
        if (reset) { page = 1; results = []; }
        const q = [
            "q=" + encodeURIComponent(query.text.trim()),
            "categories=" + categories,
            "purity=100",
            "sorting=" + sorting,
            "atleast=1920x1080",
            "page=" + page
        ];
        if (sorting === "toplist") q.push("topRange=1M");
        api.command = ["curl", "-sf", "--max-time", "15", "https://wallhaven.cc/api/v1/search?" + q.join("&")];
        loading = true;
        api.running = true;
    }

    function download(item, apply) {
        const ext = item.path.slice(item.path.lastIndexOf("."));
        const dest = folder + "/wallhaven-" + item.id + ext;
        if (mine.includes(dest)) {
            if (apply) Wallpaper.set(dest);
            return;
        }
        const d = Object.assign({}, downloading);
        d[item.id] = true;
        downloading = d;
        const proc = downloader.createObject(root, { dest: dest, itemId: item.id, apply: apply });
        proc.command = ["curl", "-sfL", "--max-time", "120", "--create-dirs", "-o", dest, item.path];
        proc.running = true;
    }

    Component.onCompleted: { refreshMine(); search(true); }

    Process {
        id: finder
        command: ["find", root.folder, "-maxdepth", "2", "-type", "f",
                  "(", "-iname", "*.jpg", "-o", "-iname", "*.jpeg", "-o", "-iname", "*.png", "-o", "-iname", "*.webp", ")"]
        stdout: StdioCollector {
            onStreamFinished: root.mine = text.split("\n").filter(l => l).sort()
        }
    }

    Process {
        id: api
        stdout: StdioCollector {
            onStreamFinished: {
                root.loading = false;
                try {
                    const d = JSON.parse(text);
                    root.results = root.results.concat(d.data);
                    root.lastPage = d.meta.last_page;
                } catch (e) {}
            }
        }
        onExited: code => { if (code !== 0) root.loading = false; }
    }

    Component {
        id: downloader
        Process {
            property string dest
            property string itemId
            property bool apply
            onExited: code => {
                const d = Object.assign({}, root.downloading);
                delete d[itemId];
                root.downloading = d;
                if (code === 0) {
                    root.refreshMine();
                    if (apply) Wallpaper.set(dest);
                }
                destroy();
            }
        }
    }

    // source switch + wallhaven controls
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Chip {
            highlighted: root.source === "mine"
            onClicked: root.source = "mine"
            Icon { name: "folder"; color: root.source === "mine" ? Theme.textOnPrimary : Theme.text }
            Label { text: "My wallpapers (" + root.mine.length + ")"; color: root.source === "mine" ? Theme.textOnPrimary : Theme.text }
        }
        Chip {
            highlighted: root.source === "wallhaven"
            onClicked: root.source = "wallhaven"
            Icon { name: "travel_explore"; color: root.source === "wallhaven" ? Theme.textOnPrimary : Theme.text }
            Label { text: "Wallhaven"; color: root.source === "wallhaven" ? Theme.textOnPrimary : Theme.text }
        }

        Item { Layout.fillWidth: true }

        Rectangle {
            visible: root.source === "wallhaven"
            Layout.preferredWidth: 170
            height: 30
            radius: 15
            color: Theme.surface
            TextInput {
                id: query
                anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: 13
                clip: true
                onAccepted: root.search(true)
                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: query.text === ""
                    text: "Search (Enter)…"
                    color: Theme.outline
                }
            }
        }

        Repeater {
            model: root.source === "wallhaven"
                ? [{ id: "toplist", label: "Top" }, { id: "date_added", label: "Latest" }, { id: "hot", label: "Hot" }, { id: "random", label: "Random" }]
                : []
            Chip {
                required property var modelData
                highlighted: root.sorting === modelData.id
                onClicked: { root.sorting = modelData.id; root.search(true); }
                Label { text: modelData.label; color: root.sorting === modelData.id ? Theme.textOnPrimary : Theme.text }
            }
        }

        Repeater {
            model: root.source === "wallhaven" ? [{ i: 0, label: "General" }, { i: 1, label: "Anime" }, { i: 2, label: "People" }] : []
            Chip {
                id: catChip
                required property var modelData
                readonly property bool on: root.categories[modelData.i] === "1"
                highlighted: on
                onClicked: {
                    const c = root.categories.split("");
                    c[modelData.i] = on ? "0" : "1";
                    if (c.join("") !== "000") { root.categories = c.join(""); root.search(true); }
                }
                Label { text: catChip.modelData.label; color: catChip.on ? Theme.textOnPrimary : Theme.text }
            }
        }
    }

    GridView {
        id: grid
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        cellWidth: width / 4
        cellHeight: cellWidth * 0.62
        model: root.source === "mine" ? root.mine : root.results

        onAtYEndChanged: {
            if (atYEnd && root.source === "wallhaven" && !root.loading && root.page < root.lastPage && root.results.length > 0) {
                root.page += 1;
                root.search(false);
            }
        }

        delegate: Item {
            id: cell
            required property var modelData
            readonly property bool isRemote: root.source === "wallhaven"
            readonly property string full: isRemote ? root.folder + "/wallhaven-" + modelData.id + modelData.path.slice(modelData.path.lastIndexOf(".")) : modelData
            readonly property bool current: Wallpaper.path === full
            readonly property bool saved: isRemote && root.mine.includes(full)
            width: grid.cellWidth
            height: grid.cellHeight

            Rectangle {
                anchors { fill: parent; margins: 5 }
                radius: 14
                color: Theme.surface
                border.width: cell.current ? 3 : 0
                border.color: Theme.accentLine
                clip: true

                Image {
                    anchors { fill: parent; margins: cell.current ? 3 : 0 }
                    source: cell.isRemote ? cell.modelData.thumbs.small : "file://" + cell.modelData
                    sourceSize.width: 320
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }

                // badges: saved / downloading / resolution
                Rectangle {
                    visible: cell.isRemote
                    anchors { right: parent.right; bottom: parent.bottom; margins: 6 }
                    height: 22
                    width: badge.implicitWidth + 12
                    radius: 11
                    color: Qt.rgba(0, 0, 0, 0.6)
                    Row {
                        id: badge
                        anchors.centerIn: parent
                        spacing: 4
                        Icon {
                            visible: cell.saved || root.downloading[cell.modelData.id] === true
                            name: root.downloading[cell.modelData.id] ? "downloading" : "download_done"
                            font.pixelSize: 14
                            color: "white"
                        }
                        Label {
                            text: cell.isRemote ? cell.modelData.resolution : ""
                            color: "white"
                            font.pixelSize: 11
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => {
                        if (!cell.isRemote) Wallpaper.set(cell.modelData);
                        else root.download(cell.modelData, mouse.button === Qt.LeftButton);
                    }
                }
            }
        }
    }

    Label {
        Layout.alignment: Qt.AlignHCenter
        text: root.source === "mine"
            ? "Click to set · files in ~/.local/share/wallpapers"
            : root.loading ? "Loading…" : "Click: download + set · Right click: save only · scroll for more"
        color: Theme.outline
        font.pixelSize: 11
    }
}
