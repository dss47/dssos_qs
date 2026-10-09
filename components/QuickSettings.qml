import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Networking

// Quick settings flyout, styled to match the bottom bar.
PanelWindow {
    id: quick

    anchors { bottom: true; right: true }
    margins { bottom: Style.flyoutBottom; right: 8 }     // 8px gap above the bar, card slides in from the right
    // panel width follows screen: 22%, clamped so it never gets tiny or huge
    implicitWidth: Math.min(480, Math.max(380, Math.round(screen.width * 0.30)))
    implicitHeight: Math.min(Math.round(screen.height * 0.7), content.implicitHeight + 32)
    color: "transparent"
    // always mapped: Hyprland animates only the first map at startup,
    // every toggle after that is our own slide. Clicks pass through when closed.
    visible: true
    mask: quick.shown ? openMask : closedMask
    exclusionMode: ExclusionMode.Ignore

    // ---- same palette as the bar ----
    readonly property color borderCol: Style.border
    readonly property color cardColor: Style.card
    readonly property color textColor: Style.text
    readonly property color dimColor: Style.dim
    readonly property color green: Style.green
    readonly property color amber: Style.amber
    readonly property color surface: Style.surface

    // ---- state ----
    // wifi state lives in NetworkManager (Networking.wifiEnabled, writable);
    // no local copy, no nmcli parse
    property bool wifiBeforePlane: true
    property bool btOn: false
    property bool planeOn: false
    property bool dndOn: false
    property bool nightOn: false
    property bool saverOn: false
    property string page: "main"
    property real brightVal: 0.7
    // coalesces slider drags into at most one brightnessctl per 60ms
    property real pendingBright: -1
    Timer {
        id: brightTimer
        interval: 60
        onTriggered: {
            if (quick.pendingBright >= 0) {
                Quickshell.execDetached(["brightnessctl", "set", Math.max(1, Math.round(quick.pendingBright * 100)) + "%"]);
                quick.pendingBright = -1;
            }
        }
    }

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volVal: sink?.audio ? sink.audio.volume : 0
    readonly property bool muted: sink?.audio ? sink.audio.muted : false

    PwObjectTracker { objects: [quick.sink] }

    HyprlandFocusGrab {
        windows: [quick]
        active: quick.shown && BarState.quickOpen
        onCleared: BarState.quickOpen = false
    }

    Region { id: openMask; item: card }
    Region { id: closedMask; width: 0; height: 0 }

    property bool shown: false
    // true while sliding out: card visible but dead (no mask, no clicks)
    property bool closing: false

    // slide the full card height so it rises from the bar like the start menu
    NumberAnimation {
        id: openAnim
        target: card
        property: "y"
        to: 0                      // no 'from': continues from current y if interrupted
        duration: Style.slideIn
        easing.type: Easing.OutCubic
    }
    NumberAnimation {
        id: closeAnim
        target: card
        property: "y"
        to: quick.height           // fully below the window's bottom edge
        duration: Style.slideOut
        easing.type: Easing.InCubic
        onFinished: quick.closing = false
    }

    Connections {
        target: BarState
        function onQuickOpenChanged() {
            if (BarState.quickOpen) {
                closeAnim.stop();              // cancel a pending hide
                // reset offscreen only if fully gone; mid-close reopens glide back
                if (!quick.shown && !quick.closing) card.y = quick.height;
                quick.closing = false;
                quick.page = "main"; btRead.running = true; brightRead.running = true;
                quick.shown = true;
                openAnim.restart();
            } else if (quick.shown) {
                openAnim.stop();
                quick.shown = false;   // drop the input mask NOW, card keeps sliding
                quick.closing = true;
                closeAnim.restart();
            }
        }
    }

    // bluetooth needs a moment after rfkill unblocks the radio
    Timer {
        id: radioSettle
        interval: 600
        onTriggered: btRead.running = true
    }
    Process {
        id: btRead
        command: ["sh", "-c", "bluetoothctl show | grep -q 'Powered: yes' && echo yes || echo no"]
        stdout: StdioCollector { onStreamFinished: quick.btOn = text.trim() === "yes" }
    }
    Process {
        id: brightRead
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = parseInt(text.split(",")[3]);
                if (!isNaN(p)) quick.brightVal = p / 100;
            }
        }
    }

    // ================= components =================
    component Tile: Rectangle {
        id: tile
        property string icon
        property bool active: false
        property bool more: false
        signal clicked(var mouse)

        Layout.fillWidth: true
        Layout.preferredHeight: 64
        radius: 12
        color: tile.active ? Style.green : Style.card

        // hover + press effect
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: Style.text
            opacity: area.pressed ? Style.press : (area.containsMouse ? Style.hover : 0)
            Behavior on opacity { NumberAnimation { duration: 100 } }
        }

        Image {
            anchors.centerIn: parent
            width: 20; height: 20
            sourceSize.width: 40; sourceSize.height: 40
            source: "../assets/icons/" + tile.icon + ".svg"
        }
        // small dot: there is more under this tile (right-click opens it)
        Rectangle {
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 6 }
            visible: tile.more
            width: 4; height: 4; radius: 2
            color: Style.text
            opacity: 0.7
        }
        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: mouse => tile.clicked(mouse)
        }
    }

    component SliderPill: Rectangle {
        id: pill
        property string icon
        property real value: 0
        property color fillColor: Style.mint
        signal moved(real v)
        signal iconClicked()

        Layout.fillWidth: true
        Layout.preferredHeight: 48
        radius: 24
        color: Style.card
        clip: true

        Rectangle {
            width: pill.value <= 0 ? 0 : Math.max(pill.height, pill.width * pill.value)
            height: parent.height
            radius: pill.radius
            color: pill.fillColor
        }
        Image {
            anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
            width: 16; height: 16
            sourceSize.width: 32; sourceSize.height: 32
            source: "../assets/icons/" + pill.icon + ".svg"
        }
        // single area: drag anywhere to slide, tap the icon to mute.
        // the old stacked areas ate the left ~11% of presses.
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            property bool fromIcon: false
            property bool dragged: false
            function v(x) { return Math.max(0, Math.min(1, x / width)); }
            onPressed: mouse => { fromIcon = mouse.x < 44; dragged = false; if (!fromIcon) { pill.moved(v(mouse.x)); } }
            onPositionChanged: mouse => {
                if (!pressed) { return; }
                if (fromIcon && Math.abs(mouse.x - 22) > 8) { dragged = true; }
                if (!fromIcon || dragged) { pill.moved(v(mouse.x)); }
            }
            onReleased: { if (fromIcon && !dragged) { pill.iconClicked(); } }
        }
    }

    component NotifCard: Rectangle {
        property string icon
        property string title
        property string body
        Layout.fillWidth: true
        Layout.preferredHeight: 54
        radius: 10
        color: Style.card
        RowLayout {
            anchors { fill: parent; margins: 10 }
            spacing: 10
            Rectangle {
                Layout.preferredWidth: 30; Layout.preferredHeight: 30
                radius: 8; color: Style.cardHi
                Image { anchors.centerIn: parent; width: 14; height: 14; sourceSize.width: 28; sourceSize.height: 28; source: "../assets/icons/" + icon + ".svg" }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Text { text: title; color: Style.text; font.pixelSize: 12; font.bold: true }
                Text {
                    Layout.fillWidth: true
                    text: body; color: Style.dim; font.pixelSize: 11
                    elide: Text.ElideRight
                }
            }
        }
    }

    // whole card slides up from behind the bar on open, instant hide on close
    Item {
        id: card
        width: parent.width
        height: content.implicitHeight + 32
        y: quick.height
        visible: quick.shown || quick.closing
        enabled: quick.shown && !quick.closing
        focus: true
        Keys.onEscapePressed: BarState.quickOpen = false

    // ================= surface (flat, no gradient) =================
    Rectangle {
        anchors.fill: parent
        radius: 14
        border.width: 1
        border.color: quick.borderCol
        color: quick.surface
    }

    ColumnLayout {
        id: content
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
        spacing: 12

        // toggles grid (main page)
        GridLayout {
            visible: quick.page === "main"
            Layout.fillWidth: true
            columns: 4
            rowSpacing: 8
            columnSpacing: 8

            Tile {
                icon: "wifi"; active: Networking.wifiEnabled; more: true
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton) { quick.page = "wifi"; return; }
                    Networking.wifiEnabled = !Networking.wifiEnabled;
                }
            }
            Tile {
                icon: "bluetooth"; active: quick.btOn; more: true
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton) { quick.page = "bt"; return; }
                    quick.btOn = !quick.btOn;
                    Quickshell.execDetached(["bluetoothctl", "power", quick.btOn ? "on" : "off"]);
                }
            }
            Tile {
                icon: "plane"; active: quick.planeOn
                onClicked: {
                    quick.planeOn = !quick.planeOn;
                    Quickshell.execDetached(["rfkill", quick.planeOn ? "block" : "unblock", "all"]);
                    if (quick.planeOn) {
                        // rfkill kills the radios: remember wifi to restore it after
                        quick.wifiBeforePlane = Networking.wifiEnabled;
                        Networking.wifiEnabled = false;
                        quick.btOn = false;
                    } else {
                        Networking.wifiEnabled = quick.wifiBeforePlane;
                        radioSettle.restart();
                    }
                }
            }
            Tile {
                icon: "bell-off"; active: quick.dndOn
                onClicked: quick.dndOn = !quick.dndOn
            }
            Tile {
                icon: "moon"; active: quick.nightOn
                onClicked: quick.nightOn = !quick.nightOn
            }
            Tile {
                icon: "battery-medium"; active: quick.saverOn
                onClicked: quick.saverOn = !quick.saverOn
            }
            Tile {
                icon: "disc"; active: false
                onClicked: console.log("Record clicked")
            }
            Tile {
                icon: "settings"; active: false
                onClicked: console.log("Settings clicked")
            }
        }

        // wifi list page (static for now, real scan later)
        ColumnLayout {
            visible: quick.page === "wifi"
            Layout.fillWidth: true
            spacing: 8
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Item {
                    Layout.preferredWidth: 32; Layout.preferredHeight: 32
                    Rectangle {
                        anchors.centerIn: parent; width: 30; height: 30; radius: 8
                        color: Style.text; opacity: wifiBack.pressed ? Style.press : (wifiBack.containsMouse ? Style.hover : 0)
                        Behavior on opacity { NumberAnimation { duration: 100 } }
                    }
                    Image {
                        anchors.centerIn: parent
                        width: 18; height: 18
                        sourceSize.width: 36; sourceSize.height: 36
                        source: "../assets/icons/chevron-left.svg"
                    }
                    MouseArea {
                        id: wifiBack
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: quick.page = "main"
                    }
                }
                Text { text: "Wi-Fi"; color: Style.text; font.pixelSize: 15; font.bold: true; Layout.fillWidth: true }
                Rectangle {
                    Layout.preferredWidth: 46; Layout.preferredHeight: 26; radius: 13
                    color: Networking.wifiEnabled ? Style.green : Style.cardHi
                    Rectangle {
                        x: Networking.wifiEnabled ? 22 : 2; y: 2; width: 22; height: 22; radius: 11; color: Style.text
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
                    }
                }
            }
            Flickable {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(152, wifiList.height)
                contentHeight: wifiList.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                // native wheel scrolling (the old handler read parent.contentY,
                // which is the content item, not the Flickable)
                Column {
                    id: wifiList
                    width: parent.width
                    spacing: 8
                    Repeater {
                        model: [
                            { name: "HUAWEI_6G", sig: "▂▄▆", lock: true, cur: true },
                            { name: "Cafe_Nord", sig: "▂▄", lock: true, cur: false },
                            { name: "FreeWifi", sig: "▂", lock: false, cur: false }
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            width: wifiList.width; height: 44; radius: 10
                            color: Style.card
                            Rectangle {
                                anchors.fill: parent; radius: 10; color: Style.text
                                opacity: wifiRow.pressed ? Style.press : (wifiRow.containsMouse ? Style.hover : 0)
                                Behavior on opacity { NumberAnimation { duration: 100 } }
                            }
                            RowLayout {
                                anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                                spacing: 8
                                Text { text: parent.parent.modelData.name; color: Style.text; font.pixelSize: 13; Layout.fillWidth: true }
                                Text { text: parent.parent.modelData.sig; color: Style.dim; font.pixelSize: 12 }
                                Image { visible: parent.parent.modelData.lock; width: 10; height: 10; sourceSize.width: 20; sourceSize.height: 20; source: "../assets/icons/lock.svg" }
                                Text { text: parent.parent.modelData.cur ? "●" : ""; color: Style.green; font.pixelSize: 12 }
                            }
                            MouseArea {
                                id: wifiRow
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: console.log(parent.modelData.name + " connect (later)")
                            }
                        }
                    }
                }
            }
        }

        // bluetooth list page (static for now, real scan later)
        ColumnLayout {
            visible: quick.page === "bt"
            Layout.fillWidth: true
            spacing: 8
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Item {
                    Layout.preferredWidth: 32; Layout.preferredHeight: 32
                    Rectangle {
                        anchors.centerIn: parent; width: 30; height: 30; radius: 8
                        color: Style.text; opacity: btBack.pressed ? Style.press : (btBack.containsMouse ? Style.hover : 0)
                        Behavior on opacity { NumberAnimation { duration: 100 } }
                    }
                    Image {
                        anchors.centerIn: parent
                        width: 18; height: 18
                        sourceSize.width: 36; sourceSize.height: 36
                        source: "../assets/icons/chevron-left.svg"
                    }
                    MouseArea {
                        id: btBack
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: quick.page = "main"
                    }
                }
                Text { text: "Bluetooth"; color: Style.text; font.pixelSize: 15; font.bold: true; Layout.fillWidth: true }
                Rectangle {
                    Layout.preferredWidth: 46; Layout.preferredHeight: 26; radius: 13
                    color: quick.btOn ? Style.green : Style.cardHi
                    Rectangle {
                        x: quick.btOn ? 22 : 2; y: 2; width: 22; height: 22; radius: 11; color: Style.text
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            quick.btOn = !quick.btOn;
                            Quickshell.execDetached(["bluetoothctl", "power", quick.btOn ? "on" : "off"]);
                        }
                    }
                }
            }
            Flickable {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(152, btList.height)
                contentHeight: btList.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                // native wheel scrolling (see wifi list)
                Column {
                    id: btList
                    width: parent.width
                    spacing: 8
                    Repeater {
                        model: [
                            { name: "Buds Pro", cur: true },
                            { name: "JBL Go", cur: false },
                            { name: "MBP-14", cur: false }
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            width: btList.width; height: 44; radius: 10
                            color: Style.card
                            Rectangle {
                                anchors.fill: parent; radius: 10; color: Style.text
                                opacity: btRow.pressed ? Style.press : (btRow.containsMouse ? Style.hover : 0)
                                Behavior on opacity { NumberAnimation { duration: 100 } }
                            }
                            RowLayout {
                                anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                                spacing: 8
                                Image { width: 14; height: 14; sourceSize.width: 28; sourceSize.height: 28; source: "../assets/icons/bluetooth.svg"; opacity: 0.7 }
                                Text { text: parent.parent.modelData.name; color: Style.text; font.pixelSize: 13; Layout.fillWidth: true }
                                Text { text: parent.parent.modelData.cur ? "●" : ""; color: Style.green; font.pixelSize: 12 }
                            }
                            MouseArea {
                                id: btRow
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: console.log(parent.modelData.name + " pair (later)")
                            }
                        }
                    }
                }
            }
        }

        // sliders (main page only)
        SliderPill {
            visible: quick.page === "main"
            icon: "sun-medium"
            value: quick.brightVal
            fillColor: quick.amber
            onMoved: v => {
                quick.brightVal = v;
                quick.pendingBright = v;
                if (!brightTimer.running) brightTimer.start();
            }
        }
        SliderPill {
            visible: quick.page === "main"
            icon: quick.muted ? "volume-x" : "volume-2"
            value: quick.muted ? 0 : quick.volVal
            fillColor: quick.green
            onMoved: v => { if (quick.sink?.audio) { quick.sink.audio.muted = false; quick.sink.audio.volume = v; } }
            onIconClicked: { if (quick.sink?.audio) quick.sink.audio.muted = !quick.sink.audio.muted; }
        }

        // notifications (main page only, still static)
        ColumnLayout {
            visible: quick.page === "main"
            Layout.fillWidth: true
            spacing: 8
            NotifCard { icon: "image"; title: "Upscale?  1h"; body: "Image resolution (1080x633) is lower than scr…" }
            NotifCard { icon: "disc"; title: "GPU Screen Recorder  1h"; body: "The recording was saved to /home/saad/Vide…" }
            NotifCard { icon: "bell"; title: "Welcome  just now"; body: "This slot is ready for the next notification…" }
        }
    }
    }
}
