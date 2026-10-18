import QtQuick
import Quickshell
import Quickshell.Wayland

// Fullscreen transparent click-catcher for click-outside-to-close on
// compositors without a focus-grab protocol (labwc).
// Invisible: zero visual change. One behavior difference vs a grab:
// the dismissing click is eaten here, not passed to the app behind.
// Sits on Bottom so the menu (Top) stays clickable above it.
PanelWindow {
    id: catcher

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Bottom

    signal clicked()

    MouseArea {
        anchors.fill: parent
        onClicked: catcher.clicked()
    }
}
