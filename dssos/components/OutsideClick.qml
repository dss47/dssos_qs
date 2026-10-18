import QtQuick
import Quickshell
import Quickshell.Wayland

// Fullscreen transparent click-catcher for click-outside-to-close on
// compositors without a focus-grab protocol.
PanelWindow {
    id: catcher

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    property int targetLayer: WlrLayer.Bottom
    color: "transparent"
    WlrLayershell.layer: targetLayer
    exclusionMode: ExclusionMode.Ignore

    signal clicked()
    signal rightClicked(real x, real y)

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        hoverEnabled: false
        onPressed: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                catcher.rightClicked(mouse.x, mouse.y);
            } else {
                catcher.clicked();
            }
        }
    }
}
