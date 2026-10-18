import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
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

    readonly property real barHeight: 48
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
    readonly property var pinnedIds: BarState.pinnedIds
    readonly property var taskApps: {
        const live = ToplevelManager.toplevels.values;
        const _entries = DesktopEntries.applications.values.length;
        const map = new Map();
        for (const id of bar.pinnedIds) {
            const pinnedEntry = DesktopEntries.heuristicLookup(id);
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

    // Dynamic network & signal reading
    property bool netConnected: false
    property string netSsid: ""
    property int netSignal: 0
    property string netIcon: "wf0"

    Process {
        id: netRead
        command: ["sh", "-c", "w=$(nmcli -t -f active,ssid,signal dev wifi 2>/dev/null | grep '^yes:' | head -n 1); if [ -n \"$w\" ]; then echo \"wifi:$w\"; else eth=$(nmcli -t -f type,state dev 2>/dev/null | grep 'connected' | head -n 1); if [ -n \"$eth\" ]; then echo \"ethernet:yes:Connected:100\"; else echo \"none:no:Disconnected:0\"; fi; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(":");
                if (parts.length >= 4 && parts[1] === "yes") {
                    bar.netConnected = true;
                    bar.netSsid = parts[2];
                    const sig = parseInt(parts[3]) || 0;
                    bar.netSignal = sig;
                    if (sig >= 80) bar.netIcon = "wf4";
                    else if (sig >= 55) bar.netIcon = "wf3";
                    else if (sig >= 30) bar.netIcon = "wf2";
                    else if (sig > 0) bar.netIcon = "wf1";
                    else bar.netIcon = "wf0";
                } else {
                    bar.netConnected = false;
                    bar.netSsid = "Disconnected";
                    bar.netSignal = 0;
                    bar.netIcon = "wf0";
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

    Component.onCompleted: netRead.running = true

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
                Layout.preferredWidth: 48
                Layout.preferredHeight: 48
                color: BarState.startOpen ? bar.cSel : (logoMouse.containsMouse ? bar.cHover : "transparent")

                Image {
                    id: logoImg
                    anchors.centerIn: parent
                    width: 28
                    height: 28
                    sourceSize.width: 56
                    sourceSize.height: 56
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
                Layout.preferredWidth: appsRow.width
                Layout.preferredHeight: 48

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
                    height: 48
                    spacing: 0

                    Repeater {
                        model: ScriptModel { values: bar.taskApps; objectProp: "appId" }

                        delegate: Rectangle {
                            id: appDelegate
                            required property var modelData
                            property var wins: modelData.toplevels
                            property string appId: modelData.appId
                            property var entry: modelData.entry

                            width: 44
                            height: 48
                            color: appMouse.containsMouse ? bar.cHover : "transparent"

                            IconImage {
                                anchors.centerIn: parent
                                implicitSize: 24
                                source: Quickshell.iconPath(entry?.icon ?? appId.toLowerCase(), "application-x-executable")
                                asynchronous: true
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
                                        const isPinned = BarState.isPinned(appId);
                                        ContextMenuState.show(p.x, bar.barHeight + 6, [
                                            { label: "Open new window", enabled: !!entryRef, action: function() { if (entryRef) entryRef.execute(); } },
                                            { label: "Focus", enabled: winsRef.length > 0, action: function() {
                                                let cur = -1;
                                                for (let ci = 0; ci < winsRef.length; ci++) {
                                                    if (winsRef[ci].activated) { cur = ci; break; }
                                                }
                                                const next = winsRef[(cur + 1) % winsRef.length];
                                                next.minimized = false;
                                                next.activate();
                                            } },
                                            { sep: true },
                                            {
                                                label: isPinned ? "Unpin from taskbar" : "Pin to taskbar",
                                                action: function() {
                                                    if (isPinned) BarState.unpinApp(appId);
                                                    else BarState.pinApp(appId);
                                                }
                                            },
                                            { sep: true },
                                            { label: "Close window", enabled: winsRef.length > 0, action: function() { if (focusedRef) focusedRef.close(); } },
                                            { label: "Close all windows", danger: true, enabled: winsRef.length > 0, action: function() { for (let wi = 0; wi < winsRef.length; wi++) winsRef[wi].close(); } }
                                        ], appName);
                                        return;
                                    }
                                    if (wins.length === 0) {
                                        if (entry) {
                                            entry.execute();
                                        } else {
                                            if (appId === "dssos-files") Quickshell.execDetached(["dssos-app", "files"]);
                                            else if (appId === "foot") Quickshell.execDetached(["foot"]);
                                            else if (appId === "dssos-tasks") Quickshell.execDetached(["dssos-app", "tasks"]);
                                            else if (appId === "dssos-settings") Quickshell.execDetached(["dssos-app", "settings"]);
                                        }
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
                Layout.preferredHeight: 48
                Layout.preferredWidth: stRow.implicitWidth + 28
                color: (BarState.quickOpen && BarState.quickTarget === "status") ? bar.cSel : (stMouse.containsMouse ? bar.cHover : "transparent")

                readonly property color stColor: "#ffffff"

                RowLayout {
                    id: stRow
                    anchors.centerIn: parent
                    spacing: 14

                    DssIcon {
                        Layout.preferredWidth: 16
                        Layout.preferredHeight: 16
                        Layout.alignment: Qt.AlignVCenter
                        name: bar.netIcon
                        color: "#ffffff"
                        opacity: bar.netConnected ? 1.0 : 0.4
                        iconSize: 16
                    }

                    DssIcon {
                        Layout.preferredWidth: 16
                        Layout.preferredHeight: 16
                        Layout.alignment: Qt.AlignVCenter
                        name: "vl"
                        color: "#ffffff"
                        opacity: !bar.audioMuted ? 1.0 : 0.6
                        iconSize: 16
                    }

                    DssIcon {
                        Layout.preferredWidth: 16
                        Layout.preferredHeight: 16
                        Layout.alignment: Qt.AlignVCenter
                        name: "bt"
                        color: "#ffffff"
                        iconSize: 16
                    }
                }

                MouseArea {
                    id: stMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (BarState.quickOpen && BarState.quickTarget === "status") {
                            BarState.quickOpen = false;
                        } else {
                            BarState.startOpen = false;
                            BarState.quickTarget = "status";
                            BarState.quickOpen = true;
                        }
                    }
                }
            }

            // ----------------- Clock (.tm)
            Rectangle {
                id: tmBox
                Layout.preferredHeight: 48
                Layout.preferredWidth: tmText.implicitWidth + 32
                color: (BarState.quickOpen && BarState.quickTarget === "clock") ? bar.cSel : (tmMouse.containsMouse ? bar.cHover : "transparent")

                Text {
                    id: tmText
                    anchors.centerIn: parent
                    text: Qt.formatTime(clock.date, "hh:mm")
                    color: "#ffffff"
                    font.pixelSize: 13
                }

                MouseArea {
                    id: tmMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (BarState.quickOpen && BarState.quickTarget === "clock") {
                            BarState.quickOpen = false;
                        } else {
                            BarState.startOpen = false;
                            BarState.quickTarget = "clock";
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
