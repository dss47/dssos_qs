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
    property bool hotspotActive: false
    property bool darkModeActive: true
    property bool recordActive: false

    // Real Power Saver state via powerprofilesctl
    Process {
        id: powerRead
        command: ["powerprofilesctl", "get"]
        stdout: StdioCollector {
            onStreamFinished: root.saverActive = (text.trim() === "power-saver")
        }
    }

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

    // Real Audio & Microphone via Pipewire
    readonly property var audioSink: Pipewire.defaultAudioSink
    readonly property real volumeVal: audioSink?.audio ? audioSink.audio.volume : 0.45
    readonly property bool audioMuted: audioSink?.audio ? audioSink.audio.muted : false
    readonly property var audioSource: Pipewire.defaultAudioSource
    readonly property bool micMuted: audioSource?.audio ? audioSource.audio.muted : false
    PwObjectTracker { objects: [root.audioSink, root.audioSource] }

    // Real Bluetooth state
    Process {
        id: btRead
        command: ["sh", "-c", "bluetoothctl show | grep -q 'Powered: yes' && echo yes || echo no"]
        stdout: StdioCollector { onStreamFinished: root.btActive = text.trim() === "yes" }
    }

    // Real Network & Signal state
    property bool wifiConnected: false
    property string wifiSsid: "Disconnected"
    property int wifiSignal: 0
    property string wifiIconName: "wf0"

    Process {
        id: netRead
        command: ["sh", "-c", "w=$(nmcli -t -f active,ssid,signal dev wifi 2>/dev/null | grep '^yes:' | head -n 1); if [ -n \"$w\" ]; then echo \"wifi:$w\"; else eth=$(nmcli -t -f type,state dev 2>/dev/null | grep 'connected' | head -n 1); if [ -n \"$eth\" ]; then echo \"ethernet:yes:Connected:100\"; else echo \"none:no:Disconnected:0\"; fi; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(":");
                if (parts.length >= 4 && parts[1] === "yes") {
                    root.wifiConnected = true;
                    root.wifiSsid = parts[2];
                    const sig = parseInt(parts[3]) || 0;
                    root.wifiSignal = sig;
                    if (sig >= 80) root.wifiIconName = "wf4";
                    else if (sig >= 55) root.wifiIconName = "wf3";
                    else if (sig >= 30) root.wifiIconName = "wf2";
                    else if (sig > 0) root.wifiIconName = "wf1";
                    else root.wifiIconName = "wf0";
                } else {
                    root.wifiConnected = false;
                    root.wifiSsid = "Disconnected";
                    root.wifiSignal = 0;
                    root.wifiIconName = "wf0";
                }
            }
        }
    }

    Timer {
        interval: 8000
        repeat: true
        running: true
        onTriggered: netRead.running = true
    }

    // Real Battery reading
    property bool batteryPresent: false
    property int batteryLevel: 100
    property string batteryStatus: "AC Power"

    Process {
        id: batRead
        command: ["sh", "-c", "cap=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null || cat /sys/class/power_supply/*/capacity 2>/dev/null); st=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null || cat /sys/class/power_supply/*/status 2>/dev/null); if [ -n \"$cap\" ]; then echo \"$cap:$st\"; else echo \"none:AC\"; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(":");
                if (parts[0] !== "none" && parts[0] !== "") {
                    root.batteryPresent = true;
                    root.batteryLevel = parseInt(parts[0]) || 0;
                    root.batteryStatus = parts[1] || "Discharging";
                } else {
                    root.batteryPresent = false;
                    root.batteryLevel = 100;
                    root.batteryStatus = "Plugged in";
                }
            }
        }
    }

    Component.onCompleted: {
        brightRead.running = true;
        btRead.running = true;
        powerRead.running = true;
        batRead.running = true;
        netRead.running = true;
    }

    component WideTile: Rectangle {
        id: tile
        property string iconName
        property string title
        property string subtitle
        property bool active: false
        signal clicked()

        Layout.fillWidth: true
        Layout.preferredHeight: 48
        radius: 0
        color: tile.active ? root.cGreen : (tileMouse.containsMouse ? "#181818" : "#0d0d0d")
        border.width: 1
        border.color: tile.active ? root.cGreen : (tileMouse.containsMouse ? "#2f2f2f" : root.cBorder)

        Behavior on color { ColorAnimation { duration: 100 } }
        Behavior on border.color { ColorAnimation { duration: 100 } }

        // Hover & press overlay
        Rectangle {
            anchors.fill: parent
            color: tile.active ? "#000000" : "#ffffff"
            opacity: tileMouse.pressed ? 0.14 : (tileMouse.containsMouse ? 0.05 : 0)
            Behavior on opacity { NumberAnimation { duration: 80 } }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 8

            DssIcon {
                Layout.alignment: Qt.AlignVCenter
                name: tile.iconName
                color: tile.active ? "#04130a" : "#ffffff"
                iconSize: 18
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 1

                Text {
                    text: tile.title
                    color: tile.active ? "#04130a" : "#ffffff"
                    font.pixelSize: 11
                    font.weight: tile.active ? Font.DemiBold : Font.Normal
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: tile.subtitle
                    color: tile.active ? "#0e341d" : root.cMuted
                    font.pixelSize: 9
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
                anchors.margins: 14
                anchors.leftMargin: 16
                anchors.rightMargin: 16

                GridLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    columns: 4
                    rowSpacing: 8
                    columnSpacing: 8

                    // 1. Wi-Fi
                    WideTile {
                        iconName: root.wifiIconName
                        title: "Wi-Fi"
                        subtitle: root.wifiSsid + (root.wifiSignal > 0 ? (" · " + root.wifiSignal + "%") : "")
                        active: root.wifiConnected || Networking.wifiEnabled
                        onClicked: {
                            Networking.wifiEnabled = !Networking.wifiEnabled;
                            netRead.running = true;
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
                        title: "Airplane"
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

                    // 4. Hotspot
                    WideTile {
                        iconName: "hs"
                        title: "Hotspot"
                        subtitle: root.hotspotActive ? "On" : "Off"
                        active: root.hotspotActive
                        onClicked: {
                            root.hotspotActive = !root.hotspotActive;
                        }
                    }

                    // 5. Night light
                    WideTile {
                        iconName: "mn"
                        title: "Night light"
                        subtitle: root.nightActive ? "On" : "After sunset"
                        active: root.nightActive
                        onClicked: {
                            root.nightActive = !root.nightActive;
                        }
                    }

                    // 6. Do not disturb
                    WideTile {
                        iconName: "dn"
                        title: "Do not disturb"
                        subtitle: root.dndActive ? "On" : "Off"
                        active: root.dndActive
                        onClicked: {
                            root.dndActive = !root.dndActive;
                        }
                    }

                    // 7. Battery saver
                    WideTile {
                        iconName: "sv"
                        title: "Battery saver"
                        subtitle: root.saverActive ? "On" : "Off"
                        active: root.saverActive
                        onClicked: {
                            root.saverActive = !root.saverActive;
                            Quickshell.execDetached(["powerprofilesctl", "set", root.saverActive ? "power-saver" : "balanced"]);
                        }
                    }

                    // 8. Dark mode
                    WideTile {
                        iconName: "dk"
                        title: "Dark mode"
                        subtitle: root.darkModeActive ? "On" : "Off"
                        active: root.darkModeActive
                        onClicked: {
                            root.darkModeActive = !root.darkModeActive;
                        }
                    }

                    // 9. Screenshot
                    WideTile {
                        iconName: "sc"
                        title: "Screenshot"
                        subtitle: "Capture area"
                        active: false
                        onClicked: {
                            BarState.quickOpen = false;
                            Quickshell.execDetached(["sh", "-c", "sleep 0.2 && grim ~/Pictures/screenshot-$(date +%s).png"]);
                        }
                    }

                    // 10. Screen record
                    WideTile {
                        iconName: "rc"
                        title: "Record"
                        subtitle: root.recordActive ? "Recording..." : "Screen record"
                        active: root.recordActive
                        onClicked: {
                            root.recordActive = !root.recordActive;
                            if (root.recordActive) {
                                BarState.quickOpen = false;
                                Quickshell.execDetached(["sh", "-c", "wf-recorder -f ~/Videos/recording-$(date +%s).mp4 2>/dev/null"]);
                            } else {
                                Quickshell.execDetached(["pkill", "-INT", "wf-recorder"]);
                            }
                        }
                    }

                    // 11. Microphone
                    WideTile {
                        iconName: "mc"
                        title: "Microphone"
                        subtitle: root.micMuted ? "Muted" : "Active"
                        active: !root.micMuted
                        onClicked: {
                            if (root.audioSource?.audio) {
                                root.audioSource.audio.muted = !root.audioSource.audio.muted;
                            }
                        }
                    }

                    // 12. Lock screen
                    WideTile {
                        iconName: "lk"
                        title: "Lock screen"
                        subtitle: "Lock session"
                        active: false
                        onClicked: {
                            BarState.quickOpen = false;
                            Quickshell.execDetached(["hyprlock"]);
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
                                text: root.batteryPresent ? (root.batteryLevel + "%") : "AC Power"
                                color: root.cText
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: root.batteryPresent ? root.batteryStatus : "Plugged in"
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
