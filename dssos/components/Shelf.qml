import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: shelfWin

    anchors {
        bottom: true
        left: true
        right: true
    }

    margins {
        bottom: 40
        left: 0
        right: 0
    }

    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    readonly property bool shelfOpen: BarState.startOpen || BarState.quickOpen
    property bool shelfVisible: false
    readonly property real shelfHeight: 250

    implicitHeight: shelfHeight
    exclusiveZone: 0
    visible: shelfVisible

    Timer {
        id: closeTimer
        interval: 250
        onTriggered: {
            if (!shelfWin.shelfOpen) {
                shelfWin.shelfVisible = false;
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
        clip: true

        Rectangle {
            id: shelfContent
            anchors.left: parent.left
            anchors.right: parent.right
            height: shelfWin.shelfHeight
            color: "#050505"
            border.width: 1
            border.color: "#1c1c1c"

            // Physical slide up: starts at shelfHeight (clipped below window bottom), slides up to 0
            y: shelfWin.shelfOpen ? 0 : shelfWin.shelfHeight

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
                onAppLaunched: (name) => shelfWin.launchByName(name)
                onActionTriggered: (act) => shelfWin.handleShelfAction(act)
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
}
