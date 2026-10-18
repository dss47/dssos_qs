import QtQuick
import QtQuick.Layouts
import "."

// Universal square slider: clamped thumb bounds, preventStealing for Flickable safety.
Item {
    id: root
    property bool enabled: true
    property real from: 0
    property real to: 100
    property real value: 50
    signal moved(real value)

    readonly property real ratio: (to > from) ? Math.max(0, Math.min(1, (value - from) / (to - from))) : 0

    opacity: root.enabled ? 1.0 : 0.4
    implicitWidth: 200
    implicitHeight: 22
    Layout.preferredWidth: 200
    Layout.preferredHeight: 22
    Layout.alignment: Qt.AlignVCenter

    // Track background
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 4
        color: Theme.control
        border.width: 1
        border.color: Theme.edge

        // Active fill bar aligned to thumb center
        Rectangle {
            width: Math.round(thumb.x + thumb.width * 0.5)
            height: parent.height
            color: Theme.accent
        }
    }

    // Square thumb clamped strictly inside [0, width - thumb.width]
    Rectangle {
        id: thumb
        x: Math.round((root.width - width) * root.ratio)
        anchors.verticalCenter: parent.verticalCenter
        width: 12
        height: 18
        color: sldHover.containsMouse || sldHover.pressed ? Qt.lighter(Theme.accent, 1.2) : Theme.accent
    }

    MouseArea {
        id: sldHover
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: root.enabled
        preventStealing: true
        cursorShape: Qt.PointingHandCursor
        onPressed: (mouse) => updateFromX(mouse.x)
        onPositionChanged: (mouse) => {
            if (pressed) updateFromX(mouse.x);
        }
        function updateFromX(mx) {
            if (root.width <= 0 || root.to <= root.from) return;
            const clampedX = Math.max(0, Math.min(root.width, mx));
            const nextVal = root.from + (clampedX / root.width) * (root.to - root.from);
            root.value = nextVal;
            root.moved(root.value);
        }
    }
}
