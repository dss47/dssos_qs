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

    // Sub-view navigation state: "" (grid), "wifi", "bluetooth", "power"
    property string activeSubView: BarState.controlSubView

    onActiveSubViewChanged: {
        BarState.controlSubView = activeSubView;
        if (activeSubView === "wifi") wifiScanProcess.running = true;
        else if (activeSubView === "bluetooth") btListProcess.running = true;
        else if (activeSubView === "power") powerRead.running = true;
    }

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
    property string currentPowerProfile: "balanced"

    // Reset subview when shelf closes
    Connections {
        target: BarState
        function onQuickOpenChanged() {
            if (!BarState.quickOpen) {
                root.activeSubView = "";
                root.selectedWifiSsid = "";
            }
        }
        function onControlSubViewChanged() {
            if (root.activeSubView !== BarState.controlSubView) {
                root.activeSubView = BarState.controlSubView;
            }
        }
    }

    // ----------------------------------------------------------------- Wi-Fi Management
    property bool wifiConnected: false
    property string wifiSsid: "Disconnected"
    property int wifiSignal: 0
    property string wifiIconName: "wf0"
    property var wifiNetworks: []
    property string selectedWifiSsid: ""
    property string wifiStatusMsg: ""

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

    Process {
        id: wifiScanProcess
        command: ["python3", ShellPaths.quickshellDir + "/dssos/scripts/wifi-helper.py", "scan"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    if (data && data.networks) {
                        root.wifiNetworks = data.networks;
                    }
                } catch(e) {}
            }
        }
    }

    Timer {
        id: wifiScanTimer
        interval: 1500
        onTriggered: {
            wifiScanProcess.running = true;
            netRead.running = true;
        }
    }

    Timer {
        interval: 8000
        repeat: true
        running: true
        onTriggered: {
            netRead.running = true;
            if (root.activeSubView === "wifi") wifiScanProcess.running = true;
        }
    }

    function connectWifi(ssid, pwd) {
        root.wifiStatusMsg = "Connecting to " + ssid + "...";
        const args = ["python3", ShellPaths.quickshellDir + "/dssos/scripts/wifi-helper.py", "connect", ssid];
        if (pwd && pwd.length > 0) args.push(pwd);
        Quickshell.execDetached(args);
        wifiScanTimer.start();
    }

    function disconnectWifi(ssid) {
        root.wifiStatusMsg = "Disconnecting...";
        Quickshell.execDetached(["python3", ShellPaths.quickshellDir + "/dssos/scripts/wifi-helper.py", "disconnect", ssid]);
        wifiScanTimer.start();
    }

    // ----------------------------------------------------------------- Bluetooth Management
    property var btDevices: []
    Process {
        id: btRead
        command: ["sh", "-c", "bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo yes || echo no"]
        stdout: StdioCollector { onStreamFinished: root.btActive = (text.trim() === "yes") }
    }

    Process {
        id: btListProcess
        command: ["python3", ShellPaths.quickshellDir + "/dssos/scripts/bluetooth-helper.py", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    if (data && data.devices) {
                        root.btDevices = data.devices;
                    }
                } catch(e) {}
            }
        }
    }

    Timer {
        id: btScanTimer
        interval: 1500
        onTriggered: {
            btRead.running = true;
            btListProcess.running = true;
        }
    }

    function connectBt(mac) {
        Quickshell.execDetached(["python3", ShellPaths.quickshellDir + "/dssos/scripts/bluetooth-helper.py", "connect", mac]);
        btScanTimer.start();
    }

    function disconnectBt(mac) {
        Quickshell.execDetached(["python3", ShellPaths.quickshellDir + "/dssos/scripts/bluetooth-helper.py", "disconnect", mac]);
        btScanTimer.start();
    }

    // ----------------------------------------------------------------- Power Profiles
    Process {
        id: powerRead
        command: ["powerprofilesctl", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                const prof = text.trim();
                root.currentPowerProfile = prof;
                root.saverActive = (prof === "power-saver");
            }
        }
    }

    function setPowerProfile(prof) {
        root.currentPowerProfile = prof;
        root.saverActive = (prof === "power-saver");
        Quickshell.execDetached(["powerprofilesctl", "set", prof]);
    }

    // ----------------------------------------------------------------- Brightness
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

    // ----------------------------------------------------------------- Audio & Mic
    readonly property var audioSink: Pipewire.defaultAudioSink
    readonly property real volumeVal: audioSink?.audio ? audioSink.audio.volume : 0.45
    readonly property bool audioMuted: audioSink?.audio ? audioSink.audio.muted : false
    readonly property var audioSource: Pipewire.defaultAudioSource
    readonly property bool micMuted: audioSource?.audio ? audioSource.audio.muted : false
    PwObjectTracker { objects: [root.audioSink, root.audioSource] }

    // ----------------------------------------------------------------- Battery
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

    // ----------------------------------------------------------------- WideTile Component
    component WideTile: Rectangle {
        id: tile
        property string iconName
        property string title
        property string subtitle
        property bool active: false
        property bool hasSubView: false
        signal clicked()
        signal subViewRequested()

        Layout.fillWidth: true
        Layout.preferredHeight: 48
        radius: 0
        color: tile.active ? root.cGreen : (bodyMouse.containsMouse || iconMouse.containsMouse ? "#181818" : "#0d0d0d")
        border.width: 1
        border.color: tile.active ? root.cGreen : (bodyMouse.containsMouse || iconMouse.containsMouse ? "#2f2f2f" : root.cBorder)

        Behavior on color { ColorAnimation { duration: 100 } }
        Behavior on border.color { ColorAnimation { duration: 100 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 6

            // Left icon area (direct toggle)
            Item {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 36
                Layout.alignment: Qt.AlignVCenter

                Rectangle {
                    anchors.fill: parent
                    color: tile.active ? "#000000" : "#ffffff"
                    opacity: iconMouse.pressed ? 0.2 : (iconMouse.containsMouse ? 0.1 : 0)
                }

                DssIcon {
                    anchors.centerIn: parent
                    name: tile.iconName
                    color: tile.active ? "#04130a" : "#ffffff"
                    iconSize: 18
                }

                MouseArea {
                    id: iconMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: tile.clicked()
                }
            }

            // Divider if expandable
            Rectangle {
                visible: tile.hasSubView
                Layout.preferredWidth: 1
                Layout.preferredHeight: 22
                Layout.alignment: Qt.AlignVCenter
                color: tile.active ? "#269056" : "#222222"
            }

            // Title, Subtitle and Chevron
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                RowLayout {
                    anchors.fill: parent
                    spacing: 4

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

                    DssIcon {
                        visible: tile.hasSubView
                        Layout.alignment: Qt.AlignVCenter
                        name: "rt"
                        color: tile.active ? "#04130a" : root.cMuted
                        iconSize: 12
                    }
                }

                MouseArea {
                    id: bodyMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (tile.hasSubView) tile.subViewRequested();
                        else tile.clicked();
                    }
                }
            }
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

        // ------------------------------------------------------------- Column 2: Grid & Expandable Sub-views
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

            // ----------------- Subview A: 4x3 Grid (Default)
            Item {
                anchors.fill: parent
                anchors.margins: 14
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                visible: root.activeSubView === ""

                GridLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    columns: 4
                    rowSpacing: 8
                    columnSpacing: 8

                    // 1. Wi-Fi (Expandable)
                    WideTile {
                        iconName: root.wifiIconName
                        title: "Wi-Fi"
                        subtitle: root.wifiSsid + (root.wifiSignal > 0 ? (" · " + root.wifiSignal + "%") : "")
                        active: root.wifiConnected || Networking.wifiEnabled
                        hasSubView: true
                        onClicked: {
                            Networking.wifiEnabled = !Networking.wifiEnabled;
                            Quickshell.execDetached(["nmcli", "radio", "wifi", Networking.wifiEnabled ? "on" : "off"]);
                            wifiScanTimer.start();
                        }
                        onSubViewRequested: {
                            root.activeSubView = "wifi";
                            wifiScanProcess.running = true;
                        }
                    }

                    // 2. Bluetooth (Expandable)
                    WideTile {
                        iconName: "bl"
                        title: "Bluetooth"
                        subtitle: root.btActive ? "Connected" : "Off"
                        active: root.btActive
                        hasSubView: true
                        onClicked: {
                            root.btActive = !root.btActive;
                            Quickshell.execDetached(["bluetoothctl", "power", root.btActive ? "on" : "off"]);
                            btScanTimer.start();
                        }
                        onSubViewRequested: {
                            root.activeSubView = "bluetooth";
                            btListProcess.running = true;
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
                            if (root.hotspotActive) {
                                Quickshell.execDetached(["sh", "-c", "wdev=$(nmcli -t -f DEVICE,TYPE dev | grep ':wifi' | head -n1 | cut -d: -f1); nmcli dev wifi hotspot ifname \"$wdev\" ssid DSSOS-Hotspot password 'dssos12345' 2>/dev/null"]);
                            } else {
                                Quickshell.execDetached(["sh", "-c", "nmcli con down Hotspot 2>/dev/null"]);
                            }
                        }
                    }

                    // 5. Night light (Generic Wayland: wlsunset)
                    WideTile {
                        iconName: "mn"
                        title: "Night light"
                        subtitle: root.nightActive ? "On (4500K)" : "Off"
                        active: root.nightActive
                        onClicked: {
                            root.nightActive = !root.nightActive;
                            if (root.nightActive) {
                                Quickshell.execDetached(["sh", "-c", "pkill -x wlsunset 2>/dev/null; wlsunset -t 4500 &"]);
                            } else {
                                Quickshell.execDetached(["pkill", "-x", "wlsunset"]);
                            }
                        }
                    }

                    // 6. Do not disturb (Generic Freedesktop notifications)
                    WideTile {
                        iconName: "dn"
                        title: "Do not disturb"
                        subtitle: root.dndActive ? "On" : "Off"
                        active: root.dndActive
                        onClicked: {
                            root.dndActive = !root.dndActive;
                            Quickshell.execDetached(["sh", "-c", "makoctl mode -t dnd 2>/dev/null || dunstctl set-paused toggle 2>/dev/null"]);
                        }
                    }

                    // 7. Battery saver (Expandable Power Modes)
                    WideTile {
                        iconName: "sv"
                        title: "Power mode"
                        subtitle: root.currentPowerProfile === "power-saver" ? "Power Saver" : (root.currentPowerProfile === "performance" ? "Performance" : "Balanced")
                        active: root.saverActive
                        hasSubView: true
                        onClicked: {
                            const next = root.saverActive ? "balanced" : "power-saver";
                            root.setPowerProfile(next);
                        }
                        onSubViewRequested: {
                            root.activeSubView = "power";
                            powerRead.running = true;
                        }
                    }

                    // 8. Dark mode (Generic GSettings)
                    WideTile {
                        iconName: "dk"
                        title: "Dark mode"
                        subtitle: root.darkModeActive ? "On" : "Off"
                        active: root.darkModeActive
                        onClicked: {
                            root.darkModeActive = !root.darkModeActive;
                            Quickshell.execDetached(["gsettings", "set", "org.gnome.desktop.interface", "color-scheme", root.darkModeActive ? "prefer-dark" : "prefer-light"]);
                        }
                    }

                    // 9. Screenshot (Generic Wayland: grim + slurp)
                    WideTile {
                        iconName: "sc"
                        title: "Screenshot"
                        subtitle: "Area capture"
                        active: false
                        onClicked: {
                            BarState.quickOpen = false;
                            Quickshell.execDetached(["sh", "-c", "sleep 0.25; mkdir -p ~/Pictures/Screenshots && grim -g \"$(slurp)\" ~/Pictures/Screenshots/screenshot-$(date +%s).png"]);
                        }
                    }

                    // 10. Screen record (Generic Wayland: wf-recorder)
                    WideTile {
                        iconName: "rc"
                        title: "Record"
                        subtitle: root.recordActive ? "Recording..." : "Screen record"
                        active: root.recordActive
                        onClicked: {
                            root.recordActive = !root.recordActive;
                            if (root.recordActive) {
                                BarState.quickOpen = false;
                                Quickshell.execDetached(["sh", "-c", "sleep 0.25; mkdir -p ~/Videos && wf-recorder -f ~/Videos/recording-$(date +%s).mp4 2>/dev/null"]);
                            } else {
                                Quickshell.execDetached(["pkill", "-INT", "wf-recorder"]);
                            }
                        }
                    }

                    // 11. Microphone (Pipewire / wpctl)
                    WideTile {
                        iconName: "mc"
                        title: "Microphone"
                        subtitle: root.micMuted ? "Muted" : "Active"
                        active: !root.micMuted
                        onClicked: {
                            if (root.audioSource?.audio) {
                                root.audioSource.audio.muted = !root.audioSource.audio.muted;
                            } else {
                                Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"]);
                            }
                        }
                    }

                    // 12. Lock screen (Standard systemd loginctl)
                    WideTile {
                        iconName: "lk"
                        title: "Lock screen"
                        subtitle: "Lock session"
                        active: false
                        onClicked: {
                            BarState.quickOpen = false;
                            Quickshell.execDetached(["loginctl", "lock-session"]);
                        }
                    }
                }
            }

            // ----------------- Subview B: Wi-Fi Networks List
            Item {
                id: wifiSubView
                anchors.fill: parent
                anchors.margins: 14
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                visible: root.activeSubView === "wifi"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 8

                    // Header
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        spacing: 8

                        Rectangle {
                            Layout.preferredWidth: 64
                            Layout.preferredHeight: 28
                            color: backWifiMouse.containsMouse ? "#1c1c1c" : "#111111"
                            border.width: 1
                            border.color: root.cBorder

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 4
                                DssIcon { name: "lf"; color: "#ffffff"; iconSize: 12 }
                                Text { text: "Back"; color: "#ffffff"; font.pixelSize: 11; font.weight: Font.DemiBold }
                            }

                            MouseArea {
                                id: backWifiMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.activeSubView = ""
                            }
                        }

                        Text {
                            text: "Wi-Fi Networks"
                            color: "#ffffff"
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            Layout.leftMargin: 4
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28
                            color: rfWifiMouse.containsMouse ? "#1c1c1c" : "#111111"
                            border.width: 1
                            border.color: root.cBorder

                            DssIcon {
                                anchors.centerIn: parent
                                name: "rf"
                                color: "#ffffff"
                                iconSize: 14
                            }

                            MouseArea {
                                id: rfWifiMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: wifiScanProcess.running = true
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 50
                            Layout.preferredHeight: 28
                            color: (root.wifiConnected || Networking.wifiEnabled) ? root.cGreen : "#181818"
                            border.width: 1
                            border.color: (root.wifiConnected || Networking.wifiEnabled) ? root.cGreen : root.cBorder

                            Text {
                                anchors.centerIn: parent
                                text: (root.wifiConnected || Networking.wifiEnabled) ? "On" : "Off"
                                color: (root.wifiConnected || Networking.wifiEnabled) ? "#04130a" : "#ffffff"
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Networking.wifiEnabled = !Networking.wifiEnabled;
                                    Quickshell.execDetached(["nmcli", "radio", "wifi", Networking.wifiEnabled ? "on" : "off"]);
                                    wifiScanTimer.start();
                                }
                            }
                        }
                    }

                    // Networks ListView
                    ListView {
                        id: wifiListView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 4
                        model: root.wifiNetworks

                        // Empty state placeholder
                        Item {
                            anchors.centerIn: parent
                            width: parent.width
                            height: 60
                            visible: root.wifiNetworks.length === 0

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 6
                                DssIcon {
                                    Layout.alignment: Qt.AlignHCenter
                                    name: "wf0"
                                    color: root.cMuted
                                    iconSize: 22
                                }
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "No Wi-Fi networks found"
                                    color: root.cMuted
                                    font.pixelSize: 11
                                }
                            }
                        }

                        delegate: Rectangle {
                            id: wifiRow
                            required property var modelData
                            width: wifiListView.width
                            height: (root.selectedWifiSsid === modelData.ssid) ? 80 : 36
                            color: modelData.inUse ? "#122518" : (wifiRowMouse.containsMouse ? "#181818" : "#0d0d0d")
                            border.width: 1
                            border.color: modelData.inUse ? root.cGreen : root.cBorder

                            Behavior on height { NumberAnimation { duration: 100 } }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 4

                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 24
                                    spacing: 8

                                    DssIcon {
                                        name: modelData.signal >= 80 ? "wf4" : (modelData.signal >= 55 ? "wf3" : (modelData.signal >= 30 ? "wf2" : "wf1"))
                                        color: modelData.inUse ? root.cGreen : "#ffffff"
                                        iconSize: 16
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0

                                        Text {
                                            text: modelData.ssid
                                            color: "#ffffff"
                                            font.pixelSize: 11
                                            font.weight: modelData.inUse ? Font.DemiBold : Font.Normal
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: modelData.inUse ? "Connected" : (modelData.secured ? (modelData.security + " · " + modelData.signal + "%") : ("Open · " + modelData.signal + "%"))
                                            color: modelData.inUse ? root.cGreen : root.cMuted
                                            font.pixelSize: 9
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                    }

                                    DssIcon {
                                        visible: modelData.secured
                                        name: "lk"
                                        color: root.cMuted
                                        iconSize: 12
                                    }

                                    DssIcon {
                                        visible: modelData.inUse
                                        name: "ck"
                                        color: root.cGreen
                                        iconSize: 14
                                    }
                                }

                                // Expandable action row
                                RowLayout {
                                    visible: root.selectedWifiSsid === modelData.ssid
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 28
                                    spacing: 6

                                    Rectangle {
                                        visible: modelData.inUse
                                        Layout.preferredWidth: 86
                                        Layout.preferredHeight: 26
                                        color: disMouse.containsMouse ? "#301515" : "#1c1c1c"
                                        border.width: 1
                                        border.color: disMouse.containsMouse ? "#a33a3a" : root.cBorder

                                        Text {
                                            anchors.centerIn: parent
                                            text: "Disconnect"
                                            color: disMouse.containsMouse ? "#ff6b6b" : "#ffffff"
                                            font.pixelSize: 10
                                        }

                                        MouseArea {
                                            id: disMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.disconnectWifi(modelData.ssid)
                                        }
                                    }

                                    Rectangle {
                                        visible: !modelData.inUse && modelData.secured
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 26
                                        color: "#080808"
                                        border.width: 1
                                        border.color: pwdInput.activeFocus ? root.cGreen : root.cBorder

                                        TextInput {
                                            id: pwdInput
                                            anchors.fill: parent
                                            anchors.leftMargin: 6
                                            anchors.rightMargin: 6
                                            verticalAlignment: TextInput.AlignVCenter
                                            color: "#ffffff"
                                            echoMode: TextInput.Password
                                            font.pixelSize: 11
                                            clip: true
                                            selectByMouse: true

                                            Text {
                                                visible: !pwdInput.text && !pwdInput.activeFocus
                                                text: "Enter password..."
                                                color: root.cMuted
                                                font.pixelSize: 10
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                        }
                                    }

                                    Rectangle {
                                        visible: !modelData.inUse
                                        Layout.preferredWidth: 72
                                        Layout.preferredHeight: 26
                                        color: connMouse.containsMouse ? "#45e390" : root.cGreen

                                        Text {
                                            anchors.centerIn: parent
                                            text: "Connect"
                                            color: "#04130a"
                                            font.pixelSize: 10
                                            font.weight: Font.DemiBold
                                        }

                                        MouseArea {
                                            id: connMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.connectWifi(modelData.ssid, modelData.secured ? pwdInput.text : "")
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: wifiRowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                z: -1
                                onClicked: {
                                    if (root.selectedWifiSsid === modelData.ssid) root.selectedWifiSsid = "";
                                    else root.selectedWifiSsid = modelData.ssid;
                                }
                            }
                        }
                    }
                }
            }

            // ----------------- Subview C: Bluetooth Devices List
            Item {
                id: btSubView
                anchors.fill: parent
                anchors.margins: 14
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                visible: root.activeSubView === "bluetooth"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 8

                    // Header
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        spacing: 8

                        Rectangle {
                            Layout.preferredWidth: 64
                            Layout.preferredHeight: 28
                            color: backBtMouse.containsMouse ? "#1c1c1c" : "#111111"
                            border.width: 1
                            border.color: root.cBorder

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 4
                                DssIcon { name: "lf"; color: "#ffffff"; iconSize: 12 }
                                Text { text: "Back"; color: "#ffffff"; font.pixelSize: 11; font.weight: Font.DemiBold }
                            }

                            MouseArea {
                                id: backBtMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.activeSubView = ""
                            }
                        }

                        Text {
                            text: "Bluetooth Devices"
                            color: "#ffffff"
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            Layout.leftMargin: 4
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28
                            color: rfBtMouse.containsMouse ? "#1c1c1c" : "#111111"
                            border.width: 1
                            border.color: root.cBorder

                            DssIcon {
                                anchors.centerIn: parent
                                name: "rf"
                                color: "#ffffff"
                                iconSize: 14
                            }

                            MouseArea {
                                id: rfBtMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: btListProcess.running = true
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 50
                            Layout.preferredHeight: 28
                            color: root.btActive ? root.cGreen : "#181818"
                            border.width: 1
                            border.color: root.btActive ? root.cGreen : root.cBorder

                            Text {
                                anchors.centerIn: parent
                                text: root.btActive ? "On" : "Off"
                                color: root.btActive ? "#04130a" : "#ffffff"
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.btActive = !root.btActive;
                                    Quickshell.execDetached(["bluetoothctl", "power", root.btActive ? "on" : "off"]);
                                    btScanTimer.start();
                                }
                            }
                        }
                    }

                    // Devices ListView
                    ListView {
                        id: btListView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 4
                        model: root.btDevices

                        // Empty state placeholder
                        Item {
                            anchors.centerIn: parent
                            width: parent.width
                            height: 60
                            visible: root.btDevices.length === 0

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 6
                                DssIcon {
                                    Layout.alignment: Qt.AlignHCenter
                                    name: "bl"
                                    color: root.cMuted
                                    iconSize: 22
                                }
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: root.btActive ? "No Bluetooth devices found" : "Bluetooth is turned off"
                                    color: root.cMuted
                                    font.pixelSize: 11
                                }
                            }
                        }

                        delegate: Rectangle {
                            required property var modelData
                            width: btListView.width
                            height: 38
                            color: modelData.connected ? "#122518" : (btRowMouse.containsMouse ? "#181818" : "#0d0d0d")
                            border.width: 1
                            border.color: modelData.connected ? root.cGreen : root.cBorder

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 8

                                DssIcon {
                                    name: modelData.icon || "bl"
                                    color: modelData.connected ? root.cGreen : "#ffffff"
                                    iconSize: 16
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    Text {
                                        text: modelData.name || modelData.mac
                                        color: "#ffffff"
                                        font.pixelSize: 11
                                        font.weight: modelData.connected ? Font.DemiBold : Font.Normal
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: modelData.connected ? ("Connected" + (modelData.battery !== null ? (" · " + modelData.battery + "%") : "")) : (modelData.paired ? "Paired" : "Ready")
                                        color: modelData.connected ? root.cGreen : root.cMuted
                                        font.pixelSize: 9
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                Rectangle {
                                    Layout.preferredWidth: 76
                                    Layout.preferredHeight: 24
                                    color: modelData.connected ? "#1c1c1c" : root.cGreen
                                    border.width: 1
                                    border.color: modelData.connected ? root.cBorder : root.cGreen

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.connected ? "Disconnect" : "Connect"
                                        color: modelData.connected ? "#ffffff" : "#04130a"
                                        font.pixelSize: 10
                                        font.weight: Font.DemiBold
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (modelData.connected) root.disconnectBt(modelData.mac);
                                            else root.connectBt(modelData.mac);
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: btRowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                z: -1
                            }
                        }
                    }
                }
            }

            // ----------------- Subview D: Power Profiles List
            Item {
                id: pwrSubView
                anchors.fill: parent
                anchors.margins: 14
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                visible: root.activeSubView === "power"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        spacing: 8

                        Rectangle {
                            Layout.preferredWidth: 64
                            Layout.preferredHeight: 28
                            color: backPwrMouse.containsMouse ? "#1c1c1c" : "#111111"
                            border.width: 1
                            border.color: root.cBorder

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 4
                                DssIcon { name: "lf"; color: "#ffffff"; iconSize: 12 }
                                Text { text: "Back"; color: "#ffffff"; font.pixelSize: 11; font.weight: Font.DemiBold }
                            }

                            MouseArea {
                                id: backPwrMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.activeSubView = ""
                            }
                        }

                        Text {
                            text: "Power Mode"
                            color: "#ffffff"
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            Layout.leftMargin: 4
                        }
                    }

                    Repeater {
                        model: [
                            { id: "power-saver", name: "Power Saver", desc: "Reduces power and clock speeds to preserve battery" },
                            { id: "balanced", name: "Balanced", desc: "Standard performance with dynamic power saving" },
                            { id: "performance", name: "Performance", desc: "Maximizes CPU frequencies and performance" }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: 44
                            color: (root.currentPowerProfile === modelData.id) ? "#122518" : (pwrRowMouse.containsMouse ? "#181818" : "#0d0d0d")
                            border.width: 1
                            border.color: (root.currentPowerProfile === modelData.id) ? root.cGreen : root.cBorder

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 8

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    Text {
                                        text: modelData.name
                                        color: "#ffffff"
                                        font.pixelSize: 11
                                        font.weight: (root.currentPowerProfile === modelData.id) ? Font.DemiBold : Font.Normal
                                    }
                                    Text {
                                        text: modelData.desc
                                        color: root.cMuted
                                        font.pixelSize: 9
                                    }
                                }

                                DssIcon {
                                    visible: root.currentPowerProfile === modelData.id
                                    name: "ck"
                                    color: root.cGreen
                                    iconSize: 14
                                }
                            }

                            MouseArea {
                                id: pwrRowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.setPowerProfile(modelData.id)
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }
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
