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
        bottom: 0
        left: 0
        right: 0
    }

    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: shelfWin.shelfOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    readonly property bool shelfOpen: BarState.startOpen || BarState.quickOpen
    readonly property real shelfHeight: 250
    property string activePanel: "none"

    implicitHeight: shelfHeight
    exclusiveZone: 0
    visible: true
    mask: shelfWin.shelfOpen ? openMask : closedMask

    // Fixed regions: prevents per-frame compositor input region updates during animation
    Region { id: openMask; width: shelfWin.width; height: shelfWin.height }
    Region { id: closedMask; width: 0; height: 0 }

    OutsideClick {
        targetLayer: WlrLayer.Top
        visible: shelfWin.shelfOpen
        onClicked: shelfWin.closeShelf()
    }

    Timer {
        id: closeTimer
        interval: 140
        onTriggered: {
            if (!shelfWin.shelfOpen) {
                shelfWin.activePanel = "none";
            }
        }
    }

    onShelfOpenChanged: {
        if (shelfOpen) {
            closeTimer.stop();
            if (BarState.startOpen) activePanel = "launcher";
            else if (BarState.quickOpen) activePanel = "control";
        } else {
            // Keep the active panel rendered while it slides down
            closeTimer.restart();
        }
    }

    Connections {
        target: BarState
        function onStartOpenChanged() {
            if (BarState.startOpen) {
                shelfWin.activePanel = "launcher";
            }
        }
        function onQuickOpenChanged() {
            if (BarState.quickOpen) {
                shelfWin.activePanel = "control";
            }
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
            anchors.fill: parent
            color: "#050505"
            border.width: 1
            border.color: "#1c1c1c"

            transform: Translate {
                y: shelfWin.shelfOpen ? 0 : shelfWin.shelfHeight
                Behavior on y {
                    NumberAnimation {
                        duration: 130
                        easing.type: Easing.OutQuad
                    }
                }
            }

            // Shelf 1: App Launcher
            ShelfLauncher {
                anchors.fill: parent
                visible: shelfWin.activePanel === "launcher"
                winScreen: shelfWin.screen
                onAppLaunched: (name) => shelfWin.launchByName(name)
                onActionTriggered: (act) => shelfWin.handleShelfAction(act)
            }

            // Shelf 2: Control Center / Quick Settings
            ShelfControl {
                anchors.fill: parent
                visible: shelfWin.activePanel === "control"
            }
        }
    }
}
