import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

// Windows 11 style: one flat full-width bar, no float, no pills.
PanelWindow {
    id: bar

    anchors {
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    implicitHeight: 48
    exclusiveZone: 48
    exclusionMode: ExclusionMode.Normal

    readonly property color textColor: "#ffffff"
    readonly property color dimColor: "#5a5c78"
    readonly property color gradLeft: "#CC141414"
    readonly property color gradMid: "#CC000000"

    // pinned launchers (must match installed .desktop IDs) + live windows grouped by appId
    // uninstalled IDs are auto-hidden by the lookup check below
    property var pinnedIds: ["kitty", "dev.zed.Zed", "helium", "org.gnome.Nautilus", "discord"]
    readonly property var taskApps: {
        // depend on live toplevels so this re-evaluates on open/close
        const live = ToplevelManager.toplevels.values;
        const map = new Map();
        for (const id of bar.pinnedIds) {
            // hide anything not actually installed — no ghost icons
            if (!DesktopEntries.heuristicLookup(id)) continue;
            const k = id.toLowerCase();
            if (!map.has(k)) map.set(k, { appId: id, toplevels: [] });
        }
        for (const tl of live) {
            const raw = (tl.appId ?? "").toString().trim();
            if (raw === "") continue;
            const k = raw.toLowerCase();
            if (!map.has(k)) map.set(k, { appId: raw, toplevels: [] });
            map.get(k).toplevels.push(tl);
        }
        return [...map.values()];
    }

    // full bar background with horizontal gradient, middle darker
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: bar.gradLeft }
            GradientStop { position: 0.5; color: bar.gradMid }
            GradientStop { position: 1.0; color: bar.gradLeft }
        }
    }

    // thin top border like Windows
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: "#552d2d2d"
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
                    color: "white"
                    opacity: (startMouse.containsMouse || startMouse.pressed) ? 0.3 : 0
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
                color: "white"
                opacity: 0.15
            }
            Item {
                Layout.preferredWidth: 8
                Layout.fillHeight: true
            }

            Repeater {
                model: bar.taskApps
                delegate: Item {
                    required property var modelData
                    property var wins: modelData.toplevels
                    property string appId: modelData.appId
                    property var entry: DesktopEntries.heuristicLookup(appId)
                    property bool isActive: wins.some(w => w.activated)
                    Layout.preferredWidth: 42
                    Layout.preferredHeight: 42
                    Rectangle {
                        anchors.centerIn: parent
                        width: 40
                        height: 40
                        radius: 8
                        color: "white"
                        opacity: (appMouse.containsMouse || appMouse.pressed) ? 0.3 : 0
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
                                color: bar.textColor
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
                                // close the focused window, or all if none focused
                                const act = wins.find(w => w.activated) ?? wins[0];
                                if (act) act.close();
                                return;
                            }
                            if (mouse.button === Qt.RightButton) {
                                // window-relative coords: bar is full-width so this == screen x
                                const p = appMouse.mapToItem(barRow, mouse.x, mouse.y);
                                const focused = wins.find(w => w.activated) ?? wins[0];
                                ContextMenuState.show(p.x, 56, [
                                    { label: "Open new window", enabled: !!entry, action: () => entry.execute() },
                                    { label: "Focus", enabled: wins.length > 0, action: () => {
                                        const cur = wins.findIndex(w => w.activated);
                                        wins[(cur + 1) % wins.length].activate();
                                    } },
                                    { label: "Close window", enabled: wins.length > 0, action: () => focused && focused.close() },
                                    { sep: true },
                                    { label: "Close all windows", danger: true, enabled: wins.length > 1, action: () => { for (const w of wins) w.close(); } }
                                ], (entry && entry.name) ? entry.name : appId);
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
                Text { text: "ENG"; color: bar.textColor; font.pixelSize: 12; font.bold: true }
                Item {
                    Layout.preferredWidth: 30
                    Layout.preferredHeight: 30
                    Rectangle {
                        anchors.centerIn: parent
                        width: 28; height: 28; radius: 6
                        color: "white"
                        opacity: (chevMouse.containsMouse || chevMouse.pressed) ? 0.3 : 0
                        Behavior on opacity { NumberAnimation { duration: 100 } }
                    }
                    Image { anchors.centerIn: parent; width: 16; height: 16; sourceSize.width: 32; sourceSize.height: 32; source: "../assets/icons/chevron-up.svg" }
                    MouseArea {
                        id: chevMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: BarState.hiddenOpen = !BarState.hiddenOpen
                    }
                }
                // one shared hover for wifi+volume, clicks stay per icon
                Item {
                    Layout.preferredWidth: iconGroup.implicitWidth + 8
                    Layout.preferredHeight: 30
                    Rectangle {
                        anchors.fill: parent
                        radius: 6
                        color: "white"
                        opacity: (groupMouse.containsMouse || wifiMouse.pressed || volMouse.pressed) ? 0.3 : 0
                        Behavior on opacity { NumberAnimation { duration: 100 } }
                    }
                    RowLayout {
                        id: iconGroup
                        anchors.centerIn: parent
                        spacing: 0
                Item {
                    Layout.preferredWidth: 30
                    Layout.preferredHeight: 30
                    Image { anchors.centerIn: parent; width: 17; height: 17; sourceSize.width: 34; sourceSize.height: 34; source: "../assets/icons/wifi.svg" }
                    MouseArea {
                        id: wifiMouse
                        anchors.fill: parent
                        onClicked: BarState.quickOpen = !BarState.quickOpen
                    }
                }
                Item {
                    Layout.preferredWidth: 30
                    Layout.preferredHeight: 30
                    Image { anchors.centerIn: parent; width: 17; height: 17; sourceSize.width: 34; sourceSize.height: 34; source: "../assets/icons/volume-2.svg" }
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
                color: bar.textColor
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
