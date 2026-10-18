import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import common

// DssOS Settings, Black skin.
// Shared components: DssScrollBar, DssRailButton, DssSidebarItem, Theme.
Window {
    id: win
    title: "Settings"
    visible: true

    minimumWidth: 800
    minimumHeight: 560
    width: 960
    height: 600
    color: Theme.bg

    property bool standalone: true
    property bool csd: false
    flags: Qt.Window | (csd ? Qt.FramelessWindowHint : 0)

    property int catIndex: 0
    property int pageIndex: 0

    property int repaintTick: 0
    property bool uiReady: false
    Component.onCompleted: {
        uiReady = true;
        // Let SettingsState poll while this window exists, and stop the moment
        // it does not.
        if (SettingsState) SettingsState.pollEnabled = true;
    }
    // There were TWO onClosing handlers in this Window (line 13 and here).
    // QML keeps the last one for a given signal, so `if (standalone) Qt.quit()`
    // was silently dead: standalone Settings.qml could never close itself.
    // Merged into a single handler.
    onClosing: {
        // The debounced writer must not swallow the very last change: without
        // this, a setting changed within 250 ms of closing was simply lost.
        if (SettingsState) {
            SettingsState.flushSave();
            SettingsState.pollEnabled = false;
        }
        if (standalone) Qt.quit();
    }
    Component.onDestruction: {
        if (SettingsState) SettingsState.pollEnabled = false;
    }
    onWidthChanged: if (uiReady) repaintDebounce.restart()
    onHeightChanged: if (uiReady) repaintDebounce.restart()

    Timer {
        id: repaintDebounce
        interval: 300
        repeat: false
        onTriggered: {
            pageFlick.contentY = 0;
            win.repaintTick++;
        }
    }

    // Tabs are deliberately few. A settings tab earns its place only when a
    // real system subsystem sits behind it that the user can actually change.
    // DssOS has no accounts system, no update story, no VPN client, no
    // telemetry and no permissions model, so those tabs were removed rather
    // than left as switches that do nothing.
    property var cats: [
        { name: "System", icon: "\uf013",
          pages: ["Display", "Sound", "Notifications", "Power & battery", "Storage", "About"] },
        { name: "Input", icon: "\uf11c",
          pages: ["Keyboard", "Mouse"] },
        { name: "Network", icon: "\uf1eb",
          pages: ["Wi-Fi"] },
        { name: "Personalization", icon: "\uf1fc",
          pages: ["Background", "Colors"] },
        { name: "Account", icon: "\uf007",
          pages: ["Your account"] },
        { name: "Desktop", icon: "\uf108",
          pages: ["Workspaces", "Decorations"] },
    ]

    function getPageSource(cat, page) {
        var pageMap = {
            "System/Display": "pages/SetPageDisplay.qml",
            "System/Sound": "pages/SetPageSound.qml",
            "System/Notifications": "pages/SetPageNotifications.qml",
            "System/Power & battery": "pages/SetPagePower.qml",
            "System/Storage": "pages/SetPageStorage.qml",
            "System/About": "pages/SetPageAbout.qml",
            "Input/Keyboard": "pages/SetPageKeyboard.qml",
            "Input/Mouse": "pages/SetPageMouse.qml",
            "Network/Wi-Fi": "pages/SetPageWifi.qml",
            "Personalization/Background": "pages/SetPageBackground.qml",
            "Personalization/Colors": "pages/SetPageColors.qml",
            "Account/Your account": "pages/SetPageAccount.qml",
            "Desktop/Workspaces": "pages/SetPageWorkspaces.qml",
            "Desktop/Decorations": "pages/SetPageDecorations.qml"
        };
        var key = cats[cat].name + "/" + cats[cat].pages[page];
        return pageMap[key] || "";
    }

    RowLayout {
        id: rootLayout
        anchors.fill: parent
        spacing: 0
        opacity: 1.0 - (win.repaintTick % 2) * 0.001

        // --- rail ------------------------------------------------------
        Rectangle {
            Layout.preferredWidth: 64
            Layout.fillHeight: true
            color: Theme.rail

            Rectangle {
                anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                width: 1
                color: Theme.edge
            }

            ColumnLayout {
                anchors { top: parent.top; topMargin: 4; horizontalCenter: parent.horizontalCenter }
                spacing: 0
                Repeater {
                    model: win.cats
                    DssRailButton {
                        iconGlyph: modelData.icon
                        selected: index === win.catIndex
                        onClicked: { win.catIndex = index; win.pageIndex = 0; }
                    }
                }
            }
        }

        // --- page list -------------------------------------------------
        Rectangle {
            Layout.preferredWidth: 230
            Layout.fillHeight: true
            color: Theme.list

            Rectangle {
                anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                width: 1
                color: Theme.edge
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: 16
                spacing: 0

                Text {
                    text: win.cats[win.catIndex].name
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                    font.family: Theme.fontFamily
                    color: Theme.text
                    Layout.leftMargin: 18
                    Layout.bottomMargin: 12
                }

                Repeater {
                    model: win.cats[win.catIndex].pages
                    DssSidebarItem {
                        label: modelData
                        selected: index === win.pageIndex
                        onClicked: win.pageIndex = index
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }

        // --- content area with universal DssScrollBar ------------------
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Flickable {
                id: pageFlick
                anchors.fill: parent
                contentWidth: width
                contentHeight: contentBox.height
                clip: true

                ColumnLayout {
                    id: contentBox
                    width: parent.width
                    spacing: 0
                    anchors { left: parent.left; right: parent.right; top: parent.top }
                    anchors.leftMargin: 28
                    anchors.rightMargin: 28
                    anchors.topMargin: 20
                    anchors.bottomMargin: 20

                    Loader {
                        Layout.fillWidth: true
                        source: win.getPageSource(win.catIndex, win.pageIndex)
                        onStatusChanged: {
                            if (status === Loader.Error)
                                console.warn("settings page failed:", source, errorString());
                        }
                    }

                    // Placeholder for any unmapped pages
                    ColumnLayout {
                        visible: win.getPageSource(win.catIndex, win.pageIndex) === ""
                        spacing: 8
                        Text {
                            text: win.cats[win.catIndex].pages[win.pageIndex]
                            font.pixelSize: 24
                            font.weight: Font.DemiBold
                            color: Theme.text
                        }
                        Text {
                            text: "Nothing here yet."
                            font.pixelSize: 13
                            color: Theme.muted
                        }
                    }
                }
            }

            // Shared universal scrollbar
            DssScrollBar {
                target: pageFlick
            }
        }
    }
}
