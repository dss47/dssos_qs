import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

Item {
    id: root

    implicitHeight: 250
    clip: true

    signal appLaunched(string name)
    signal actionTriggered(string action)

    readonly property color cCard: "#131313"
    readonly property color cBorder: "#1c1c1c"
    readonly property color cText: "#f0f0f0"
    readonly property color cMuted: "#8c8c8c"
    readonly property color cGreen: "#34c77b"
    readonly property color cCtl: "#0a0a0a"

    readonly property string username: ShellPaths.userName
    readonly property string userInitial: (root.username.length > 0 ? root.username[0] : "U").toUpperCase()
    readonly property string userDisplayName: root.username.length > 0 ? (root.username[0].toUpperCase() + root.username.slice(1)) : "User"

    property var recentFiles: []
    Process {
        id: recentProc
        command: ["python3", ShellPaths.quickshellDir + "/dssos/scripts/get-recent-files.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.recentFiles = JSON.parse(text.trim());
                } catch (e) {
                    root.recentFiles = [];
                }
            }
        }
    }

    Component.onCompleted: {
        recentProc.running = true;
    }

    readonly property var installedApps: {
        const apps = DesktopEntries.applications.values
            .filter(e => !e.noDisplay && e.name && e.name.trim() !== "");
        const preferred = ["files", "terminal", "foot", "browser", "tasks", "settings", "editor", "calculator"];
        apps.sort((a, b) => {
            const an = a.name.toLowerCase();
            const bn = b.name.toLowerCase();
            const ai = preferred.findIndex(p => an.includes(p));
            const bi = preferred.findIndex(p => bn.includes(p));
            if (ai !== -1 && bi !== -1) return ai - bi;
            if (ai !== -1) return -1;
            if (bi !== -1) return 1;
            return a.name.localeCompare(b.name);
        });
        return apps.slice(0, 15).map(e => ({
            entry: e,
            name: e.name,
            icon: e.icon,
            fallback: "app",
            color: root.cGreen
        }));
    }

    readonly property var searchResults: {
        const q = searchInput.text.trim().toLowerCase();
        if (q === "") return null;
        const list = DesktopEntries.applications.values
            .filter(e => !e.noDisplay && (e.name.toLowerCase().includes(q) || (e.genericName ?? "").toLowerCase().includes(q) || (e.comment ?? "").toLowerCase().includes(q)))
            .slice(0, 15);
        return list.map(e => ({ entry: e, name: e.name, icon: e.icon, fallback: "app", color: "#34c77b" }));
    }

    readonly property var displayedApps: searchResults !== null ? searchResults : installedApps

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ------------------------------------------------------------- Column 1: Search & Recent
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
                spacing: 0

                // Search box
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38
                    color: root.cCtl
                    border.width: 0

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 2
                        color: searchInput.activeFocus ? root.cGreen : "#232323"
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 10

                        DssIcon {
                            name: "sr"
                            color: root.cMuted
                            iconSize: 16
                        }

                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            verticalAlignment: TextInput.AlignVCenter
                            color: root.cText
                            font.pixelSize: 13
                            clip: true
                            onAccepted: {
                                if (root.displayedApps && root.displayedApps.length > 0) {
                                    const a = root.displayedApps[0];
                                    BarState.startOpen = false;
                                    if (a.entry) a.entry.execute();
                                    else root.appLaunched(a.name);
                                }
                            }

                            Text {
                                text: "Search apps and files"
                                color: root.cMuted
                                font.pixelSize: 13
                                visible: searchInput.text === "" && !searchInput.activeFocus
                            }
                        }
                    }
                }

                // Recent Header
                Text {
                    text: "Recent"
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: root.cMuted
                    Layout.topMargin: 20
                    Layout.bottomMargin: 6
                }

                // Recent List Items
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Repeater {
                        model: root.recentFiles

                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36
                            color: riMouse.containsMouse ? "#111111" : "transparent"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 12

                                DssIcon {
                                    name: modelData.icon
                                    color: modelData.color
                                    iconSize: 18
                                }

                                Text {
                                    text: modelData.name
                                    color: root.cText
                                    font.pixelSize: 13
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: modelData.date
                                    color: root.cMuted
                                    font.pixelSize: 11
                                }
                            }

                            MouseArea {
                                id: riMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    BarState.startOpen = false;
                                    Quickshell.execDetached(["xdg-open", modelData.path]);
                                }
                            }
                        }
                    }

                    Text {
                        visible: root.recentFiles.length === 0
                        text: "No recent files"
                        color: root.cMuted
                        font.pixelSize: 12
                        Layout.topMargin: 8
                        Layout.leftMargin: 8
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }

        // ------------------------------------------------------------- Column 2: All Apps Grid
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
                anchors.margins: 22
                anchors.leftMargin: 24
                anchors.rightMargin: 24

                GridLayout {
                    anchors.fill: parent
                    columns: 5
                    columnSpacing: 4
                    rowSpacing: 4

                    Repeater {
                        model: root.displayedApps

                        delegate: Rectangle {
                            required property var modelData
                            property var entry: modelData.entry ?? (modelData.id ? DesktopEntries.heuristicLookup(modelData.id) : null)

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: giMouse.containsMouse ? "#111111" : "transparent"

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 6

                                Item {
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.preferredWidth: 28
                                    Layout.preferredHeight: 28

                                    IconImage {
                                        id: appIconImg
                                        anchors.fill: parent
                                        source: Quickshell.iconPath(entry?.icon ?? modelData.icon ?? "application-x-executable", "application-x-executable")
                                        asynchronous: true
                                        visible: status === Image.Ready
                                    }

                                    DssIcon {
                                        anchors.centerIn: parent
                                        name: modelData.fallback ?? "app"
                                        color: modelData.color ?? root.cGreen
                                        iconSize: 24
                                        visible: appIconImg.status !== Image.Ready
                                    }
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: (entry && entry.name) ? entry.name : modelData.name
                                    color: root.cText
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                    Layout.maximumWidth: 90
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }

                            MouseArea {
                                id: giMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (entry) {
                                        root.appLaunched(entry.name);
                                        entry.execute();
                                    } else {
                                        root.appLaunched(modelData.name);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ------------------------------------------------------------- Column 3: Profile & Session
        Rectangle {
            Layout.preferredWidth: 200
            Layout.fillHeight: true
            color: "transparent"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 22
                anchors.leftMargin: 24
                anchors.rightMargin: 24
                spacing: 0

                // Profile row
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    color: prMouse.containsMouse ? "#111111" : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 4
                        anchors.rightMargin: 4
                        spacing: 12

                        Rectangle {
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28
                            color: root.cGreen

                            Text {
                                anchors.centerIn: parent
                                text: root.userInitial
                                color: "#04130a"
                                font.pixelSize: 13
                                font.weight: Font.Bold
                            }
                        }

                        Text {
                            text: root.userDisplayName
                            color: root.cText
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                        }
                    }

                    MouseArea {
                        id: prMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(["dssos-app", "settings"])
                    }
                }

                // Session Header
                Text {
                    text: "Session"
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: root.cMuted
                    Layout.topMargin: 16
                    Layout.bottomMargin: 8
                }

                // Session Actions
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    // Action 1: Sleep
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 34
                        color: slMouse.containsMouse ? "#111111" : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            spacing: 12

                            DssIcon {
                                Layout.preferredWidth: 16
                                Layout.preferredHeight: 16
                                Layout.alignment: Qt.AlignVCenter
                                name: "sl"
                                color: root.cMuted
                                iconSize: 16
                            }

                            Text {
                                text: "Sleep"
                                color: root.cText
                                font.pixelSize: 13
                            }
                        }

                        MouseArea {
                            id: slMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.actionTriggered("Sleep")
                        }
                    }

                    // Action 2: Restart
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 34
                        color: rsMouse.containsMouse ? "#111111" : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            spacing: 12

                            DssIcon {
                                Layout.preferredWidth: 16
                                Layout.preferredHeight: 16
                                Layout.alignment: Qt.AlignVCenter
                                name: "rs"
                                color: root.cMuted
                                iconSize: 16
                            }

                            Text {
                                text: "Restart"
                                color: root.cText
                                font.pixelSize: 13
                            }
                        }

                        MouseArea {
                            id: rsMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.actionTriggered("Restart")
                        }
                    }

                    // Action 3: Shut down
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 34
                        color: sdMouse.containsMouse ? "#111111" : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            spacing: 12

                            DssIcon {
                                Layout.preferredWidth: 16
                                Layout.preferredHeight: 16
                                Layout.alignment: Qt.AlignVCenter
                                name: "pw"
                                color: root.cMuted
                                iconSize: 16
                            }

                            Text {
                                text: "Shut down"
                                color: root.cText
                                font.pixelSize: 13
                            }
                        }

                        MouseArea {
                            id: sdMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.actionTriggered("Shut down")
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }
    }
}
