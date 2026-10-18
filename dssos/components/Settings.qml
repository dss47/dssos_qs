import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import Quickshell

// DssOS Settings, Black skin (see SETTINGS_DESIGN.md).
// Three columns: icon rail 56px, page list 210px, content. No title bar —
// the compositor draws it (csd stays false). Square corners everywhere.
Window {
    id: win
    title: "Settings"
    visible: true
    onClosing: if (standalone) Qt.quit()
    minimumWidth: 800
    minimumHeight: 560
    width: 960
    height: 600
    color: SettingsTheme.bg

    // standalone = launched via `qs -p` (owns its lifetime).
    // embedded   = loaded by the dssos-apps host (host owns lifetime).
    property bool standalone: true
    property bool csd: false
    flags: Qt.Window | (csd ? Qt.FramelessWindowHint : 0)

    property int catIndex: 0
    property int pageIndex: 0

    // Fullscreen/resize fix: Qt doesn't commit a fresh Wayland buffer after
    // the configure storm settles, so Wayfire scales the stale one until a
    // real repaint happens. Debounce resizes, then flip an invisible visual
    // (root opacity 1.0 <-> 0.999) to force a post-settle scene-graph repaint.
    property int repaintTick: 0
    property bool uiReady: false
    Component.onCompleted: uiReady = true
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

    property var cats: [
        { name: "System", icon: "\uf013",
          pages: ["Display", "Sound", "Notifications", "Power & battery", "Storage", "Multitasking", "Clipboard", "About"] },
        { name: "Input", icon: "\uf11c",
          pages: ["Keyboard", "Mouse"] },
        { name: "Network", icon: "\uf1eb",
          pages: ["Wi-Fi", "VPN"] },
        { name: "Personalization", icon: "\uf1fc",
          pages: ["Background", "Colors"] },
        { name: "Apps", icon: "\uf009",
          pages: ["Installed apps"] },
        { name: "Accounts", icon: "\uf007",
          pages: ["Your info"] },
        { name: "Time & language", icon: "\uf017",
          pages: ["Date & time"] },
        { name: "Desktop", icon: "\uf108",
          pages: ["Workspaces", "Decorations"] },
        { name: "Privacy", icon: "\uf132",
          pages: ["General"] },
        { name: "Updates", icon: "\uf019",
          pages: ["DssOS Update"] },
    ]

    property string pageFile: (catIndex === 0 && pageIndex === 0) ? "SetPageDisplay.qml" : ""

    RowLayout {
        id: rootLayout
        anchors.fill: parent
        spacing: 0
        // invisible to the eye, dirty to the scene graph (see repaintTick)
        opacity: 1.0 - (win.repaintTick % 2) * 0.001

        // --- rail ------------------------------------------------------
        Rectangle {
            Layout.preferredWidth: 64
            Layout.fillHeight: true
            color: SettingsTheme.rail
            Rectangle {
                anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                width: 1
                color: SettingsTheme.edge
            }
            ColumnLayout {
                anchors { top: parent.top; topMargin: 4; horizontalCenter: parent.horizontalCenter }
                spacing: 0
                Repeater {
                    model: win.cats
                    SetRailButton {
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
            color: SettingsTheme.list
            Rectangle {
                anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                width: 1
                color: SettingsTheme.edge
            }
            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: 16
                spacing: 0
                Text {
                    text: win.cats[win.catIndex].name
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                    color: SettingsTheme.text
                    Layout.leftMargin: 18
                    Layout.bottomMargin: 12
                }
                Repeater {
                    model: win.cats[win.catIndex].pages
                    SetPageItem {
                        label: modelData
                        selected: index === win.pageIndex
                        onClicked: win.pageIndex = index
                    }
                }
                Item { Layout.fillHeight: true }
            }
        }

        // --- content ---------------------------------------------------
        Flickable {
            id: pageFlick
            Layout.fillWidth: true
            Layout.fillHeight: true
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
                    source: win.pageFile
                    onStatusChanged: {
                        if (status === Loader.Error)
                            console.warn("settings page failed:", source, errorString());
                    }
                }
                // placeholder for pages not built yet
                ColumnLayout {
                    visible: win.pageFile === ""
                    spacing: 8
                    Text {
                        text: win.cats[win.catIndex].pages[win.pageIndex]
                        font.pixelSize: 26
                        font.weight: Font.DemiBold
                        color: SettingsTheme.text
                    }
                    Text {
                        text: "Nothing here yet."
                        font.pixelSize: 13
                        color: SettingsTheme.muted
                    }
                }
            }
        }
    }
}
