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
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    function openMenu(x, y) {
        Quickshell.execDetached(["qs", "ipc", "-p", ShellPaths.appsHost, "call", "context", "hide"]);
        ContextMenuState.showAt(x, y, [
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
            },
            {
                label: "Settings",
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
            }
        }
    }
}
