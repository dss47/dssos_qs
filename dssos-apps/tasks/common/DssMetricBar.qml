import QtQuick
import "."

Rectangle {
    id: root
    width: parent ? parent.width : 100
    height: 3
    color: Theme.card

    property real ratio: 0.0 // 0.0 to 1.0
    property color barColor: Theme.accent

    Rectangle {
        id: fillBar
        height: 3
        width: Math.max(2, Math.min(root.width, root.width * root.ratio))
        color: root.barColor

        Behavior on width {
            NumberAnimation { duration: 150 }
        }
    }
}
