import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import Quickshell.Networking

// Windows 11 style: one flat full-width bar, no float, no pills.
PanelWindow {
    id: bar

    anchors {
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    implicitHeight: Style.barHeight
    exclusiveZone: Style.barHeight
    exclusionMode: ExclusionMode.Normal


    // pinned launchers (must match installed .desktop IDs) + live windows grouped by appId
    // uninstalled IDs are auto-hidden by the lookup check below
    property var pinnedIds: ["kitty", "dev.zed.Zed", "helium", "org.gnome.Nautilus", "discord"]
    readonly property var taskApps: {
        // depend on live toplevels so this re-evaluates on open/close.
        // desktop entries resolve once here, not per delegate.
        const live = ToplevelManager.toplevels.values;
        const map = new Map();
        for (const id of bar.pinnedIds) {
            // hide anything not actually installed — no ghost icons
            const pinnedEntry = DesktopEntries.heuristicLookup(id);
            if (!pinnedEntry) continue;
            const k = id.toLowerCase();
            if (!map.has(k)) map.set(k, { appId: id, entry: pinnedEntry, toplevels: [] });
        }
        for (const tl of live) {
            const raw = (tl.appId ?? "").toString().trim();
            if (raw === "") continue;
            const k = raw.toLowerCase();
            if (!map.has(k)) map.set(k, { appId: raw, entry: DesktopEntries.heuristicLookup(raw), toplevels: [] });
            map.get(k).toplevels.push(tl);
        }
        return [...map.values()];
    }

    // tray mute state (icon only; sliders live in quick settings)
    readonly property var audioSink: Pipewire.defaultAudioSink
    readonly property bool audioMuted: audioSink?.audio ? audioSink.audio.muted : false
    PwObjectTracker { objects: [bar.audioSink] }

    // live wifi state for the tray indicator (NetworkManager pushes, no polling)
    // Networking is a singleton: use it directly, never instantiate it
    readonly property var wifiDev: {
        for (const d of Networking.devices.values) { if (d.type === DeviceType.Wifi) { return d; } }
        return null;
    }
    readonly property var activeWifi: {
        if (!wifiDev) { return null; }
        for (const n of wifiDev.networks.values) { if (n.connected) { return n; } }
        return null;
    }
    readonly property bool wifiUp: Networking.wifiEnabled && !!activeWifi
    readonly property int wifiLevel: !activeWifi ? 0 : Math.max(1, Math.ceil((activeWifi.signalStrength ?? 0) / 25))

    // full bar background with horizontal gradient, middle darker
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Style.barEdge }
            GradientStop { position: 0.5; color: Style.barMid }
            GradientStop { position: 1.0; color: Style.barEdge }
        }
    }

    // thin top border like Windows
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Style.borderSoft
    }

    RowLayout {
        id: barRow
        anchors.fill: parent
        anchors.rightMargin: 14
        spacing: 6

        // left: start + apps (edge to edge, no dead clicks)
        RowLayout {
            spacing: 4

            // left edge margin is part of the start button: no dead clicks in the corner
            Item {
                Layout.preferredWidth: 8
                Layout.fillHeight: true
                MouseArea {
                    anchors.fill: parent
                    onClicked: BarState.startOpen = !BarState.startOpen
                }
            }

            // Start button, clean 4 boxes in distro green
            Item {
                Layout.preferredWidth: 42
                Layout.preferredHeight: 42
                Rectangle {
                    anchors.centerIn: parent
                    width: 40
                    height: 40
                    radius: 8
                    color: Style.text
                    opacity: startMouse.pressed ? Style.press : (startMouse.containsMouse ? Style.hover : 0)
                    Behavior on opacity { NumberAnimation { duration: 100 } }
                }
                Grid {
                    anchors.centerIn: parent
                    columns: 2
                    spacing: 4
                    Repeater {
                        model: 4
                        Rectangle {
                            width: 10; height: 10; radius: 3
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "#5ff09a" }
                                GradientStop { position: 1.0; color: "#25a75c" }
                            }
                        }
                    }
                }
                MouseArea {
                    id: startMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: BarState.startOpen = !BarState.startOpen
                }
            }

            // gap + divider + gap: clear break between Start and apps
            Item {
                Layout.preferredWidth: 8
                Layout.fillHeight: true
                MouseArea {
                    anchors.fill: parent
                    onClicked: BarState.startOpen = !BarState.startOpen
                }
            }
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 1
                Layout.preferredHeight: 24
                color: Style.text
                opacity: 0.15
            }
            Item {
                Layout.preferredWidth: 8
                Layout.fillHeight: true
            }

            Repeater {
                // ScriptModel diffs by appId: unchanged rows keep their delegates
                // (and icons) when windows open or close elsewhere
                model: ScriptModel { values: bar.taskApps; objectProp: "appId" }
                delegate: Item {
                    required property var modelData
                    property var wins: modelData.toplevels
                    property string appId: modelData.appId
                    property var entry: modelData.entry
                    Layout.preferredWidth: 42
                    Layout.preferredHeight: 42
                    Rectangle {
                        anchors.centerIn: parent
                        width: 40
                        height: 40
                        radius: 8
                        color: Style.text
                        opacity: appMouse.pressed ? Style.press : (appMouse.containsMouse ? Style.hover : 0)
                        Behavior on opacity { NumberAnimation { duration: 100 } }
                    }
                    IconImage {
                        anchors.centerIn: parent
                        implicitSize: 28
                        source: Quickshell.iconPath(entry?.icon ?? appId.toLowerCase(), "application-x-executable")
                        asynchronous: true
                    }
                    // running indicators: one pill per open window.
                    // single window = original 8px pill; groups shrink to share 36px.
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 0
                        spacing: 2
                        visible: wins.length > 0
                        Repeater {
                            model: Math.min(wins.length, 8)
                            delegate: Rectangle {
                                required property int index
                                width: wins.length === 1 ? 8 : Math.max(3, Math.min(8, Math.floor((36 - (Math.min(wins.length, 8) - 1) * 2) / Math.min(wins.length, 8))))
                                height: 4
                                radius: 2
                                color: Style.text
                                opacity: (wins[index] && wins[index].activated) ? 1.0 : 0.35
                            }
                        }
                    }
                    MouseArea {
                        id: appMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                        onClicked: mouse => {
                            if (mouse.button === Qt.MiddleButton) {
                                // close the focused window (first one if none focused)
                                const act = wins.find(w => w.activated) ?? wins[0];
                                if (act) act.close();
                                return;
                            }
                            if (mouse.button === Qt.RightButton) {
                                // window-relative coords: bar is full-width so this == screen x
                                const p = appMouse.mapToItem(barRow, mouse.x, mouse.y);
                                let focused = null;
                                for (let fi = 0; fi < wins.length; fi++) {
                                    if (wins[fi].activated) { focused = wins[fi]; break; }
                                }
                                if (!focused && wins.length > 0) { focused = wins[0]; }
                                const entryRef = entry;
                                const winsRef = wins;
                                const focusedRef = focused;
                                const appName = (entryRef && entryRef.name) ? entryRef.name : appId;
                                ContextMenuState.show(p.x, 56, [
                                    { label: "Open new window", enabled: !!entryRef, action: function() { entryRef.execute(); } },
                                    { label: "Focus", enabled: winsRef.length > 0, action: function() {
                                        let cur = -1;
                                        for (let ci = 0; ci < winsRef.length; ci++) {
                                            if (winsRef[ci].activated) { cur = ci; break; }
                                        }
                                        winsRef[(cur + 1) % winsRef.length].activate();
                                    } },
                                    { label: "Close window", enabled: winsRef.length > 0, action: function() { if (focusedRef) { focusedRef.close(); } } },
                                    { sep: true },
                                    { label: "Close all windows", danger: true, enabled: winsRef.length > 1, action: function() { for (let wi = 0; wi < winsRef.length; wi++) { winsRef[wi].close(); } } }
                                ], appName);
                                return;
                            }
                            if (wins.length === 0) {
                                if (entry) entry.execute();
                                else console.log(appId + " not installed (edit pinnedIds)");
                                return;
                            }
                            // cycle through grouped windows
                            const cur = wins.findIndex(w => w.activated);
                            wins[(cur + 1) % wins.length].activate();
                        }
                    }
                }
            }
        }

        // right spacer
        Item { Layout.fillWidth: true }

        // tray: ENG plain text, chevron opens overflow, speaker opens quick settings
        RowLayout {
            id: trayRow
            spacing: 0
                Text { text: "ENG"; color: Style.text; font.pixelSize: 12; font.bold: true }
                Item {
                    Layout.preferredWidth: 30
                    Layout.preferredHeight: 30
                    Rectangle {
                        anchors.centerIn: parent
                        width: 28; height: 28; radius: 6
                        color: Style.text
                        opacity: chevMouse.pressed ? Style.press : (chevMouse.containsMouse ? Style.hover : 0)
                        Behavior on opacity { NumberAnimation { duration: 100 } }
                    }
                    Image { anchors.centerIn: parent; width: 16; height: 16; sourceSize.width: 32; sourceSize.height: 32; source: "../assets/icons/chevron-up.svg" }
                    MouseArea {
                        id: chevMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            BarState.hiddenX = chevMouse.mapToItem(barRow, chevMouse.width / 2, 0).x;
                            BarState.hiddenOpen = !BarState.hiddenOpen;
                        }
                    }
                }
                // one shared hover for wifi+volume, clicks stay per icon
                Item {
                    Layout.preferredWidth: iconGroup.implicitWidth + 8
                    Layout.preferredHeight: 30
                    Rectangle {
                        anchors.fill: parent
                        radius: 6
                        color: Style.text
                        opacity: (wifiMouse.pressed || volMouse.pressed) ? Style.press : (groupMouse.containsMouse ? Style.hover : 0)
                        Behavior on opacity { NumberAnimation { duration: 100 } }
                    }
                    RowLayout {
                        id: iconGroup
                        anchors.centerIn: parent
                        spacing: 0
                Item {
                    Layout.preferredWidth: 30
                    Layout.preferredHeight: 30
                    // live signal bars; diagonal slash when no link
                    Item {
                        anchors.centerIn: parent
                        width: 22
                        height: 16
                        opacity: Networking.wifiEnabled ? 1.0 : 0.45
                        // wifi fan: dot + 3 arcs, lit up to wifiLevel
                        Shape {
                            anchors.fill: parent
                            ShapePath {
                                strokeWidth: 2.2
                                capStyle: ShapePath.RoundCap
                                strokeColor: Qt.rgba(1, 1, 1, bar.wifiLevel >= 4 ? 1.0 : 0.25)
                                fillColor: "transparent"
                                PathMove { x: 2.87; y: 5.07 }
                                PathArc { x: 19.13; y: 5.07; radiusX: 11.5; radiusY: 11.5; useLargeArc: false }
                            }
                            ShapePath {
                                strokeWidth: 2.2
                                capStyle: ShapePath.RoundCap
                                strokeColor: Qt.rgba(1, 1, 1, bar.wifiLevel >= 3 ? 1.0 : 0.25)
                                fillColor: "transparent"
                                PathMove { x: 4.99; y: 7.19 }
                                PathArc { x: 17.01; y: 7.19; radiusX: 8.5; radiusY: 8.5; useLargeArc: false }
                            }
                            ShapePath {
                                strokeWidth: 2.2
                                capStyle: ShapePath.RoundCap
                                strokeColor: Qt.rgba(1, 1, 1, bar.wifiLevel >= 2 ? 1.0 : 0.25)
                                fillColor: "transparent"
                                PathMove { x: 7.46; y: 9.66 }
                                PathArc { x: 14.54; y: 9.66; radiusX: 5; radiusY: 5; useLargeArc: false }
                            }
                        }
                        Rectangle {
                            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 1.2 }
                            width: 3.2
                            height: 3.2
                            radius: 1.6
                            color: Qt.rgba(1, 1, 1, bar.wifiLevel >= 1 ? 1.0 : 0.25)
                        }
                        Rectangle {
                            visible: !bar.wifiUp
                            anchors.centerIn: parent
                            width: 22
                            height: 2
                            radius: 1
                            rotation: -45
                            color: Style.text
                        }
                    }
                    MouseArea {
                        id: wifiMouse
                        anchors.fill: parent
                        onClicked: BarState.quickOpen = !BarState.quickOpen
                    }
                }
                Item {
                    Layout.preferredWidth: 30
                    Layout.preferredHeight: 30
                    Image { anchors.centerIn: parent; width: 17; height: 17; sourceSize.width: 34; sourceSize.height: 34; source: "../assets/icons/" + (bar.audioMuted ? "volume-x" : "volume-2") + ".svg" }
                    MouseArea {
                        id: volMouse
                        anchors.fill: parent
                        onClicked: BarState.quickOpen = !BarState.quickOpen
                    }
                }
                    }
                    MouseArea {
                        id: groupMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                    }
                }
            Text {
                Layout.leftMargin: 8
                text: Qt.formatTime(clock.date, "hh:mm") + "\n" + Qt.formatDate(clock.date, "dd.MM.yyyy")
                color: Style.text
                font.pixelSize: 12
                horizontalAlignment: Text.AlignHCenter
                lineHeight: 1.1
            }
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
