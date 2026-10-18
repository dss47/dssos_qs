import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import Quickshell.Networking

PanelWindow {
    id: bar

    anchors {
        bottom: true
        left: true
        right: true
    }

    margins {
        bottom: 0
        left: 0
        right: 0
    }

    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    readonly property real barHeight: 40
    implicitHeight: barHeight
    exclusiveZone: barHeight
    exclusionMode: ExclusionMode.Normal

    // Design tokens from HTML
    readonly property color cDock: "#000000"
    readonly property color cBorder: "#1c1c1c"
    readonly property color cText: "#f0f0f0"
    readonly property color cMuted: "#8c8c8c"
    readonly property color cGreen: "#34c77b"
    readonly property color cSel: "#1b1b1b"
    readonly property color cHover: "#151515"

    // App state & live tracking
    property var pinnedIds: ["dssos-files", "foot", "dssos-tasks", "dssos-settings"]
    readonly property var taskApps: {
        const live = ToplevelManager.toplevels.values;
        const map = new Map();
        for (const id of bar.pinnedIds) {
            const pinnedEntry = DesktopEntries.heuristicLookup(id);
            if (!pinnedEntry) continue;
            const k = id.toLowerCase();
            if (!map.has(k)) map.set(k, { appId: id, entry: pinnedEntry, toplevels: [] });
        }
        for (const tl of live) {
            const raw = (tl.appId ?? "").toString().trim();
            if (raw === "") continue;
            const rl = raw.toLowerCase();
            const title = ((tl.title ?? "").toString().trim());
            const isQs = (rl === "quickshell" || rl === "qs" || rl === "org.quickshell");
            const key = (isQs && title !== "") ? title : raw;
            const k = key.toLowerCase();
            if (!map.has(k)) map.set(k, { appId: key, entry: DesktopEntries.heuristicLookup(key), toplevels: [] });
            map.get(k).toplevels.push(tl);
        }
        return [...map.values()];
    }

    readonly property int activeAppIndex: {
        for (let i = 0; i < taskApps.length; i++) {
            const wins = taskApps[i].toplevels;
            if (wins && wins.some(w => w.activated)) {
                return i;
            }
        }
        return -1;
    }

    // Audio & Network tray tracking
    readonly property var audioSink: Pipewire.defaultAudioSink
    readonly property bool audioMuted: audioSink?.audio ? audioSink.audio.muted : false
    PwObjectTracker { objects: [bar.audioSink] }

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

    Rectangle {
        id: taskbarRow
        anchors.fill: parent
        color: bar.cDock

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: bar.cBorder
        }

        RowLayout {
            id: barRow
            anchors.fill: parent
            spacing: 0

            // ----------------- Logo Button (.lg)
            Rectangle {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                color: BarState.startOpen ? bar.cSel : (logoMouse.containsMouse ? bar.cHover : "transparent")

                Image {
                    id: logoImg
                    anchors.centerIn: parent
                    width: 22
                    height: 22
                    sourceSize.width: 44
                    sourceSize.height: 44
                    source: "../assets/logo.png"
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    asynchronous: true
                }

                MouseArea {
                    id: logoMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (BarState.startOpen) BarState.startOpen = false;
                        else {
                            BarState.quickOpen = false;
                            BarState.startOpen = true;
                        }
                    }
                }
            }

            // ----------------- Apps Container (.apps)
            Item {
                id: appsContainer
                Layout.leftMargin: 4
                Layout.preferredWidth: appsRow.implicitWidth
                Layout.preferredHeight: 40

                // Ink active indicator
                Rectangle {
                    id: ink
                    width: 44
                    height: 3
                    y: 0
                    x: bar.activeAppIndex >= 0 ? bar.activeAppIndex * 44 : 0
                    color: bar.cGreen
                    visible: bar.activeAppIndex >= 0

                    Behavior on x {
                        NumberAnimation {
                            duration: 140
                            easing.type: Easing.OutQuad
                        }
                    }
                }

                Row {
                    id: appsRow
                    anchors.fill: parent

                    Repeater {
                        model: ScriptModel { values: bar.taskApps; objectProp: "appId" }

                        delegate: Rectangle {
                            id: appDelegate
                            required property var modelData
                            property var wins: modelData.toplevels
                            property string appId: modelData.appId
                            property var entry: modelData.entry

                            width: 44
                            height: 40
                            color: appMouse.containsMouse ? bar.cHover : "transparent"

                            IconImage {
                                anchors.centerIn: parent
                                implicitSize: 20
                                source: Quickshell.iconPath(entry?.icon ?? appId.toLowerCase(), "application-x-executable")
                                asynchronous: true
                            }

                            // Running indicators: small pills/dots under open windows
                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 2
                                spacing: 2
                                visible: wins.length > 0

                                Repeater {
                                    model: Math.min(wins.length, 5)
                                    delegate: Rectangle {
                                        required property int index
                                        width: wins.length === 1 ? 6 : 3
                                        height: 2
                                        color: (wins[index] && wins[index].activated) ? bar.cGreen : "#777777"
                                    }
                                }
                            }

                            MouseArea {
                                id: appMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

                                onClicked: mouse => {
                                    if (mouse.button === Qt.MiddleButton) {
                                        const act = wins.find(w => w.activated) ?? wins[0];
                                        if (act) act.close();
                                        return;
                                    }
                                    if (mouse.button === Qt.RightButton) {
                                        const p = appMouse.mapToItem(barRow, mouse.x, mouse.y);
                                        let focused = wins.find(w => w.activated) ?? wins[0];
                                        const entryRef = entry;
                                        const winsRef = wins;
                                        const focusedRef = focused;
                                        const appName = (entryRef && entryRef.name) ? entryRef.name : appId;
                                        ContextMenuState.showAt(p.x, bar.y, [
                                            { label: "Open new window", enabled: !!entryRef, action: function() { entryRef.execute(); } },
                                            { label: "Focus", enabled: winsRef.length > 0, action: function() {
                                                let cur = -1;
                                                for (let ci = 0; ci < winsRef.length; ci++) {
                                                    if (winsRef[ci].activated) { cur = ci; break; }
                                                }
                                                const next = winsRef[(cur + 1) % winsRef.length];
                                                next.minimized = false;
                                                next.activate();
                                            } },
                                            { label: "Close window", enabled: winsRef.length > 0, action: function() { if (focusedRef) focusedRef.close(); } },
                                            { sep: true },
                                            { label: "Close all windows", danger: true, enabled: winsRef.length > 0, action: function() { for (let wi = 0; wi < winsRef.length; wi++) winsRef[wi].close(); } }
                                        ]);
                                        return;
                                    }
                                    if (wins.length === 0) {
                                        if (entry) entry.execute();
                                        return;
                                    }
                                    const focused = wins.find(w => w.activated);
                                    if (focused) {
                                        focused.minimized = true;
                                    } else {
                                        const target = wins.find(w => w.minimized) ?? wins[0];
                                        target.minimized = false;
                                        target.activate();
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ----------------- Spacer (.sp)
            Item { Layout.fillWidth: true }

            // ----------------- Status Indicators (.st)
            Rectangle {
                id: stBox
                Layout.preferredHeight: 40
                Layout.preferredWidth: stRow.implicitWidth + 28
                color: BarState.quickOpen ? bar.cSel : (stMouse.containsMouse ? bar.cHover : "transparent")

                readonly property color stColor: (BarState.quickOpen || stMouse.containsMouse) ? bar.cText : bar.cMuted

                RowLayout {
                    id: stRow
                    anchors.centerIn: parent
                    spacing: 14

                    Image {
                        width: 15; height: 15
                        sourceSize: Qt.size(30, 30)
                        source: "../assets/icons/wifi.svg"
                        opacity: bar.wifiUp ? 1.0 : 0.45
                    }

                    Image {
                        width: 15; height: 15
                        sourceSize: Qt.size(30, 30)
                        source: "../assets/icons/" + (bar.audioMuted ? "volume-x.svg" : "volume-2.svg")
                        opacity: !bar.audioMuted ? 1.0 : 0.45
                    }

                    Image {
                        width: 15; height: 15
                        sourceSize: Qt.size(30, 30)
                        source: "../assets/icons/battery-medium.svg"
                        opacity: 0.85
                    }
                }

                MouseArea {
                    id: stMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (BarState.quickOpen) BarState.quickOpen = false;
                        else {
                            BarState.startOpen = false;
                            BarState.quickOpen = true;
                        }
                    }
                }
            }

            // ----------------- Clock (.tm)
            Rectangle {
                Layout.preferredHeight: 40
                Layout.preferredWidth: tmText.implicitWidth + 32
                color: BarState.quickOpen ? bar.cSel : (tmMouse.containsMouse ? bar.cHover : "transparent")

                Text {
                    id: tmText
                    anchors.centerIn: parent
                    text: Qt.formatTime(clock.date, "hh:mm")
                    color: (BarState.quickOpen || tmMouse.containsMouse) ? bar.cText : bar.cMuted
                    font.pixelSize: 13
                }

                MouseArea {
                    id: tmMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (BarState.quickOpen) BarState.quickOpen = false;
                        else {
                            BarState.startOpen = false;
                            BarState.quickOpen = true;
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
