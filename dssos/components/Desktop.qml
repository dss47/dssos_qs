import QtQuick
import Quickshell
import Quickshell.Wayland

// Desktop background surface for right-click desktop context menu
PanelWindow {
    id: desktopWin

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    Rectangle {
        id: refreshPulse
        anchors.fill: parent
        color: "#ffffff"
        opacity: 0
        visible: opacity > 0

        NumberAnimation on opacity {
            id: refreshAnim
            from: 0.12
            to: 0.0
            duration: 120
            running: false
        }
    }

    function refresh() {
        refreshAnim.restart();
    }

    Shortcut {
        sequence: "F5"
        onActivated: desktopWin.refresh()
    }

    function openMenu(x, y) {
        Quickshell.execDetached(["qs", "ipc", "-p", ShellPaths.appsHost, "call", "context", "hide"]);
        ContextMenuState.showAt(x, y, [
            {
                label: "Refresh",
                hint: "F5",
                action: function() { desktopWin.refresh(); }
            },
            { sep: true },
            {
                label: "Terminal",
                hint: "Super+T",
                action: function() { Quickshell.execDetached(["foot"]); }
            },
            {
                label: "Files",
                hint: "Super+E",
                action: function() { Quickshell.execDetached(["dssos-app", "files"]); }
            },
            {
                label: "Tasks",
                hint: "Ctrl+Shift+Esc",
                action: function() { Quickshell.execDetached(["dssos-app", "tasks"]); }
            },
            { sep: true },
            {
                label: "Display",
                action: function() { Quickshell.execDetached(["dssos-app", "settings"]); }
            }
        ], desktopWin.height);
    }

    Component.onCompleted: {
        ContextMenuState.desktopMenuCallback = openMenu;
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPressed: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                desktopWin.openMenu(mouse.x, mouse.y);
            } else {
                ContextMenuState.hide();
                BarState.startOpen = false;
                BarState.quickOpen = false;
                desktopWin.forceActiveFocus();
            }
        }
    }
}
