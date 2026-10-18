import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import Quickshell.Networking

Item {
    id: root

    implicitHeight: 250
    clip: true

    readonly property color cCard: "#131313"
    readonly property color cBorder: "#1c1c1c"
    readonly property color cText: "#f0f0f0"
    readonly property color cMuted: "#8c8c8c"
    readonly property color cGreen: "#34c77b"
    readonly property color cCtl: "#0a0a0a"

    // Real system states
    property bool wifiBeforePlane: true
    property bool btActive: false
    property bool planeActive: false
    property bool dndActive: false
    property bool nightActive: false
    property bool saverActive: false

    // Real Brightness
    property real brightnessVal: 0.70
    property real pendingBright: -1
    Timer {
        id: brightTimer
        interval: 60
        onTriggered: {
            if (root.pendingBright >= 0) {
                Quickshell.execDetached(["brightnessctl", "set", Math.max(1, Math.round(root.pendingBright * 100)) + "%"]);
                root.pendingBright = -1;
            }
        }
    }
    Process {
        id: brightRead
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.split(",");
                if (parts.length >= 4) {
                    const p = parseInt(parts[3]);
                    if (!isNaN(p)) root.brightnessVal = p / 100;
                }
            }
        }
    }

    // Real Volume via Pipewire
    readonly property var audioSink: Pipewire.defaultAudioSink
    readonly property real volumeVal: audioSink?.audio ? audioSink.audio.volume : 0.45
    readonly property bool audioMuted: audioSink?.audio ? audioSink.audio.muted : false
    PwObjectTracker { objects: [root.audioSink] }

    // Real Bluetooth state
    Process {
        id: btRead
        command: ["sh", "-c", "bluetoothctl show | grep -q 'Powered: yes' && echo yes || echo no"]
        stdout: StdioCollector { onStreamFinished: root.btActive = text.trim() === "yes" }
    }

    // Real Wi-Fi state
    readonly property var wifiDev: {
        for (const d of Networking.devices.values) { if (d.type === DeviceType.Wifi) return d; }
        return null;
    }
    readonly property var activeWifi: {
        if (!wifiDev) return null;
        for (const n of wifiDev.networks.values) { if (n.connected) return n; }
        return null;
    }
    readonly property bool wifiUp: Networking.wifiEnabled && !!activeWifi
    readonly property string wifiSsid: activeWifi?.ssid ?? (Networking.wifiEnabled ? "Connected" : "Disconnected")

    Component.onCompleted: {
        brightRead.running = true;
        btRead.running = true;
    }

    component WideTile: Rectangle {
        id: tile
        property string iconName
        property string title
        property string subtitle
        property bool active: false
        signal clicked()

        Layout.fillWidth: true
        Layout.preferredHeight: 56
        radius: 0
        color: tile.active ? "#11291b" : (tileMouse.containsMouse ? "#181818" : "#0d0d0d")
        border.width: 1
        border.color: tile.active ? root.cGreen : root.cBorder

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 12

            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                Layout.alignment: Qt.AlignVCenter
                color: tile.active ? root.cGreen : "#181818"
                border.width: 1
                border.color: tile.active ? root.cGreen : "#262626"

                DssIcon {
                    anchors.centerIn: parent
                    name: tile.iconName
                    color: tile.active ? "#04130a" : root.cMuted
                    iconSize: 16
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                Text {
                    text: tile.title
                    color: root.cText
                    font.pixelSize: 12
                    font.weight: tile.active ? Font.DemiBold : Font.Normal
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: tile.subtitle
                    color: tile.active ? root.cGreen : root.cMuted
                    font.pixelSize: 10
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
        }

        MouseArea {
            id: tileMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.clicked()
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ------------------------------------------------------------- Column 1: Big Clock & Date
        Rectangle {
            Layout.preferredWidth: 280
            Layout.fillHeight: true
            color: "transparent"

            Rectangle {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 1
                color: root.cBorder
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 22
                anchors.leftMargin: 24
                anchors.rightMargin: 24
                spacing: 6

                Item { Layout.fillHeight: true }

                Text {
                    text: Qt.formatTime(clock.date, "hh:mm")
                    color: root.cText
                    font.pixelSize: 44
                    font.weight: Font.Normal
                    lineHeight: 1.0
                }

                Text {
                    text: Qt.formatDate(clock.date, "dddd, d MMMM yyyy")
                    color: root.cMuted
                    font.pixelSize: 13
                }

                Item { Layout.fillHeight: true }
            }
        }

        // ------------------------------------------------------------- Column 2: Wide Action Buttons Grid (2x3)
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "transparent"

            Rectangle {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 1
                color: root.cBorder
            }

            Item {
                anchors.fill: parent
                anchors.margins: 20
                anchors.leftMargin: 22
                anchors.rightMargin: 22

                GridLayout {
                    anchors.fill: parent
                    columns: 2
                    rowSpacing: 8
                    columnSpacing: 8

                    // 1. Wi-Fi
                    WideTile {
                        iconName: "wf"
                        title: "Wi-Fi"
                        subtitle: root.wifiSsid
                        active: Networking.wifiEnabled
                        onClicked: {
                            Networking.wifiEnabled = !Networking.wifiEnabled;
                        }
                    }

                    // 2. Bluetooth
                    WideTile {
                        iconName: "bl"
                        title: "Bluetooth"
                        subtitle: root.btActive ? "Connected" : "Off"
                        active: root.btActive
                        onClicked: {
                            root.btActive = !root.btActive;
                            Quickshell.execDetached(["bluetoothctl", "power", root.btActive ? "on" : "off"]);
                        }
                    }

                    // 3. Airplane mode
                    WideTile {
                        iconName: "pl"
                        title: "Airplane mode"
                        subtitle: root.planeActive ? "On" : "Off"
                        active: root.planeActive
                        onClicked: {
                            root.planeActive = !root.planeActive;
                            Quickshell.execDetached(["rfkill", root.planeActive ? "block" : "unblock", "all"]);
                            if (root.planeActive) {
                                root.wifiBeforePlane = Networking.wifiEnabled;
                                Networking.wifiEnabled = false;
                                root.btActive = false;
                            } else {
                                Networking.wifiEnabled = root.wifiBeforePlane;
                            }
                        }
                    }

                    // 4. Night light
                    WideTile {
                        iconName: "mn"
                        title: "Night light"
                        subtitle: root.nightActive ? "On" : "After sunset"
                        active: root.nightActive
                        onClicked: {
                            root.nightActive = !root.nightActive;
                        }
                    }

                    // 5. Do not disturb
                    WideTile {
                        iconName: "dn"
                        title: "Do not disturb"
                        subtitle: root.dndActive ? "On" : "Off"
                        active: root.dndActive
                        onClicked: {
                            root.dndActive = !root.dndActive;
                        }
                    }

                    // 6. Battery saver
                    WideTile {
                        iconName: "sv"
                        title: "Battery saver"
                        subtitle: root.saverActive ? "On" : "Off"
                        active: root.saverActive
                        onClicked: {
                            root.saverActive = !root.saverActive;
                        }
                    }
                }
            }
        }

        // ------------------------------------------------------------- Column 3: Sliders & Controls
        Rectangle {
            Layout.preferredWidth: 300
            Layout.fillHeight: true
            color: "transparent"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 22
                anchors.leftMargin: 24
                anchors.rightMargin: 24
                spacing: 8

                // Slider 1: Brightness
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    color: "transparent"

                    RowLayout {
                        anchors.fill: parent
                        spacing: 14

                        Item {
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24
                            Layout.alignment: Qt.AlignVCenter

                            DssIcon {
                                anchors.centerIn: parent
                                name: "sn"
                                color: root.cMuted
                                iconSize: 16
                            }
                        }

                        Item {
                            id: bTrack
                            Layout.fillWidth: true
                            Layout.preferredHeight: 4
                            Layout.alignment: Qt.AlignVCenter

                            Rectangle {
                                anchors.fill: parent
                                color: root.cCard
                            }

                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: parent.width * root.brightnessVal
                                color: root.cGreen
                            }

                            Rectangle {
                                width: 10
                                height: 16
                                anchors.verticalCenter: parent.verticalCenter
                                x: (bTrack.width * root.brightnessVal) - 5
                                color: root.cGreen
                            }

                            MouseArea {
                                anchors.fill: parent
                                anchors.topMargin: -10
                                anchors.bottomMargin: -10
                                cursorShape: Qt.PointingHandCursor
                                onPressed: (mouse) => {
                                    root.brightnessVal = Math.max(0, Math.min(1, mouse.x / bTrack.width));
                                    root.pendingBright = root.brightnessVal;
                                    brightTimer.restart();
                                }
                                onPositionChanged: (mouse) => {
                                    if (pressed) {
                                        root.brightnessVal = Math.max(0, Math.min(1, mouse.x / bTrack.width));
                                        root.pendingBright = root.brightnessVal;
                                        brightTimer.restart();
                                    }
                                }
                            }
                        }

                        Text {
                            text: Math.round(root.brightnessVal * 100) + "%"
                            color: root.cMuted
                            font.pixelSize: 13
                            Layout.preferredWidth: 40
                            Layout.alignment: Qt.AlignVCenter
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }

                // Slider 2: Volume
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    color: "transparent"

                    RowLayout {
                        anchors.fill: parent
                        spacing: 14

                        Item {
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24
                            Layout.alignment: Qt.AlignVCenter

                            DssIcon {
                                anchors.centerIn: parent
                                name: "vl"
                                color: root.cMuted
                                iconSize: 16
                            }
                        }

                        Item {
                            id: vTrack
                            Layout.fillWidth: true
                            Layout.preferredHeight: 4
                            Layout.alignment: Qt.AlignVCenter

                            Rectangle {
                                anchors.fill: parent
                                color: root.cCard
                            }

                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: parent.width * (root.audioMuted ? 0 : root.volumeVal)
                                color: root.cGreen
                            }

                            Rectangle {
                                width: 10
                                height: 16
                                anchors.verticalCenter: parent.verticalCenter
                                x: (vTrack.width * (root.audioMuted ? 0 : root.volumeVal)) - 5
                                color: root.cGreen
                            }

                            MouseArea {
                                anchors.fill: parent
                                anchors.topMargin: -10
                                anchors.bottomMargin: -10
                                cursorShape: Qt.PointingHandCursor
                                onPressed: (mouse) => {
                                    const v = Math.max(0, Math.min(1, mouse.x / vTrack.width));
                                    if (root.audioSink?.audio) {
                                        root.audioSink.audio.volume = v;
                                        root.audioSink.audio.muted = (v === 0);
                                    }
                                }
                                onPositionChanged: (mouse) => {
                                    if (pressed) {
                                        const v = Math.max(0, Math.min(1, mouse.x / vTrack.width));
                                        if (root.audioSink?.audio) {
                                            root.audioSink.audio.volume = v;
                                            root.audioSink.audio.muted = (v === 0);
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            text: (root.audioMuted ? 0 : Math.round(root.volumeVal * 100)) + "%"
                            color: root.cMuted
                            font.pixelSize: 13
                            Layout.preferredWidth: 40
                            Layout.alignment: Qt.AlignVCenter
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }

                // Battery Row + Settings Quick Action
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    color: "transparent"

                    RowLayout {
                        anchors.fill: parent
                        spacing: 14

                        Item {
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24
                            Layout.alignment: Qt.AlignVCenter

                            DssIcon {
                                anchors.centerIn: parent
                                name: "bt"
                                color: root.cMuted
                                iconSize: 16
                            }
                        }

                        RowLayout {
                            spacing: 8
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter

                            Text {
                                text: "84%"
                                color: root.cText
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: "3 h 40 min left"
                                color: root.cMuted
                                font.pixelSize: 13
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28
                            Layout.alignment: Qt.AlignVCenter
                            color: setMouse.containsMouse ? "#202020" : "#131313"
                            border.width: 1
                            border.color: root.cBorder

                            DssIcon {
                                anchors.centerIn: parent
                                name: "gr"
                                color: root.cMuted
                                iconSize: 14
                            }

                            MouseArea {
                                id: setMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    BarState.quickOpen = false;
                                    Quickshell.execDetached(["dssos-app", "settings"]);
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
