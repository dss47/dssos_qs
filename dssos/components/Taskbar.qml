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

    readonly property bool shelfOpen: BarState.startOpen || BarState.quickOpen
    property bool shelfVisible: shelfOpen
    readonly property real shelfHeight: 250
    readonly property real barHeight: 40

    implicitHeight: barHeight + (shelfVisible ? shelfHeight : 0)
    exclusiveZone: barHeight
    exclusionMode: ExclusionMode.Normal

    Timer {
        id: closeTimer
        interval: 260
        onTriggered: {
            if (!bar.shelfOpen) {
                bar.shelfVisible = false;
            }
        }
    }

    onShelfOpenChanged: {
        if (shelfOpen) {
            closeTimer.stop();
            shelfVisible = true;
        } else {
            closeTimer.start();
        }
    }

    // Design tokens from HTML
    readonly property color cDock: "#000000"
    readonly property color cShelf: "#050505"
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

    function closeShelf() {
        BarState.startOpen = false;
        BarState.quickOpen = false;
    }

    function launchByName(name) {
        closeShelf();
        const n = (name ?? "").toLowerCase();
        if (n === "files") {
            Quickshell.execDetached(["dssos-app", "files"]);
        } else if (n === "terminal") {
            Quickshell.execDetached(["foot"]);
        } else if (n === "browser") {
            Quickshell.execDetached(["xdg-open", "https://google.com"]);
        } else if (n === "settings") {
            Quickshell.execDetached(["dssos-app", "settings"]);
        } else if (n === "tasks") {
            Quickshell.execDetached(["dssos-app", "tasks"]);
        } else if (n === "code") {
            Quickshell.execDetached(["foot", "nvim"]);
        } else {
            const entry = DesktopEntries.heuristicLookup(n);
            if (entry) entry.execute();
        }
    }

    function handleShelfAction(act) {
        closeShelf();
        if (act === "Sleep") Quickshell.execDetached(["systemctl", "suspend"]);
        else if (act === "Restart") Quickshell.execDetached(["systemctl", "reboot"]);
        else if (act === "Shut down") Quickshell.execDetached(["systemctl", "poweroff"]);
    }

    Item {
        anchors.fill: parent

        // ============================================================= 1. THE SHELF (slides up from behind taskbar)
        Item {
            id: shelfBox
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: taskbarRow.top
            height: bar.shelfHeight
            clip: true
            visible: bar.shelfVisible
            z: 1

            Rectangle {
                id: shelfContent
                anchors.left: parent.left
                anchors.right: parent.right
                height: bar.shelfHeight
                color: bar.cShelf
                border.width: 1
                border.color: bar.cBorder

                // Slide animation: when closed, y is shelfHeight (pushed below the clip boundary);
                // when open, y is 0 (rises into full view).
                y: bar.shelfOpen ? 0 : bar.shelfHeight

                Behavior on y {
                    NumberAnimation {
                        duration: 240
                        easing.type: Easing.OutCubic
                    }
                }

                // Shelf 1: App Launcher
                ShelfLauncher {
                    anchors.fill: parent
                    visible: BarState.startOpen
                    opacity: visible ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                    onAppLaunched: (name) => bar.launchByName(name)
                    onActionTriggered: (act) => bar.handleShelfAction(act)
                }

                // Shelf 2: Control Center / Quick Settings
                ShelfControl {
                    anchors.fill: parent
                    visible: BarState.quickOpen
                    opacity: visible ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
            }
        }

        // ============================================================= 2. THE TASKBAR (strictly pinned to bottom)
        Rectangle {
            id: taskbarRow
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: bar.barHeight
            color: bar.cDock
            z: 2

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
                                duration: 200
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

                        DssIcon {
                            name: "wf"
                            color: stBox.stColor
                            opacity: bar.wifiUp ? 1.0 : 0.6
                            iconSize: 16
                        }

                        DssIcon {
                            name: "vl"
                            color: stBox.stColor
                            opacity: !bar.audioMuted ? 1.0 : 0.6
                            iconSize: 16
                        }

                        DssIcon {
                            name: "bt"
                            color: stBox.stColor
                            iconSize: 16
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
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
