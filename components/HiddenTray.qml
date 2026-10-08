import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// Hidden-icons overflow box, opens above the chevron.
PanelWindow {
    id: hidden

    anchors { bottom: true; right: true }
    margins { bottom: 56; right: 80 }
    implicitWidth: contentRow.implicitWidth + 24
    implicitHeight: 52
    color: "transparent"
    visible: true
    mask: hidden.shown ? openMask : closedMask
    exclusionMode: ExclusionMode.Ignore

    property bool shown: false
    // true while sliding out: card visible but dead (no mask, no clicks)
    property bool closing: false

    HyprlandFocusGrab {
        windows: [hidden]
        active: hidden.shown && BarState.hiddenOpen
        onCleared: BarState.hiddenOpen = false
    }

    Region { id: openMask; item: card }
    Region { id: closedMask; width: 0; height: 0 }

    NumberAnimation {
        id: openAnim
        target: card
        property: "y"
        to: 0
        duration: 200
        easing.type: Easing.OutCubic
    }
    NumberAnimation {
        id: closeAnim
        target: card
        property: "y"
        to: hidden.height
        duration: 180
        easing.type: Easing.InCubic
        onFinished: hidden.closing = false
    }

    Connections {
        target: BarState
        function onHiddenOpenChanged() {
            if (BarState.hiddenOpen) {
                closeAnim.stop();
                // reset offscreen only if fully gone; mid-close reopens glide back
                if (!hidden.shown && !hidden.closing) card.y = hidden.height;
                hidden.closing = false;
                hidden.shown = true;
                openAnim.restart();
            } else if (hidden.shown) {
                openAnim.stop();
                hidden.shown = false;   // drop the input mask NOW, card keeps sliding
                hidden.closing = true;
                closeAnim.restart();
            }
        }
    }

    Item {
        id: card
        width: parent.width
        height: parent.height
        y: hidden.height
        visible: hidden.shown || hidden.closing
        enabled: hidden.shown && !hidden.closing

        Rectangle {
            anchors.fill: parent
            radius: 14
            color: "#101010"
            border.width: 1
            border.color: "#2d2d2d"
        }

        RowLayout {
            id: contentRow
            anchors.centerIn: parent
            spacing: 4
            Repeater {
                model: ["bluetooth", "plane", "moon", "settings"]
                delegate: Item {
                    required property string modelData
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    Rectangle {
                        anchors.centerIn: parent
                        width: 32; height: 32; radius: 8
                        color: "white"
                        opacity: (hMouse.containsMouse || hMouse.pressed) ? 0.3 : 0
                        Behavior on opacity { NumberAnimation { duration: 100 } }
                    }
                    Image {
                        anchors.centerIn: parent
                        width: 18; height: 18
                        sourceSize.width: 36; sourceSize.height: 36
                        source: "../assets/icons/" + parent.modelData + ".svg"
                    }
                    MouseArea {
                        id: hMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: console.log(parent.modelData + " (later)")
                    }
                }
            }
        }
    }
}
