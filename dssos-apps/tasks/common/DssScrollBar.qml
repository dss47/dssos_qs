import QtQuick
import "."

Item {
    id: root
    property var target: null
    property int barWidth: Theme.scrollWidth

    width: barWidth
    anchors.top: target ? target.top : parent.top
    anchors.bottom: target ? target.bottom : parent.bottom
    anchors.right: target ? target.right : parent.right
    z: 99

    visible: target ? (target.visibleArea ? target.visibleArea.heightRatio < 1.0 : false) : false

    Rectangle {
        id: thumb
        width: root.barWidth
        anchors.right: parent.right
        y: (root.target && root.target.visibleArea) ? root.target.visibleArea.yPosition * root.height : 0
        height: (root.target && root.target.visibleArea) ? Math.max(24, root.target.visibleArea.heightRatio * root.height) : 24
        color: thumbMouse.containsMouse ? Theme.scrollThumbHover : Theme.scrollThumb

        MouseArea {
            id: thumbMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.ArrowCursor
            drag.target: parent
            drag.axis: Drag.YAxis
            drag.minimumY: 0
            drag.maximumY: Math.max(0, root.height - thumb.height)

            onPositionChanged: {
                if (drag.active && root.target && root.target.contentHeight > root.target.height) {
                    var range = root.height - thumb.height;
                    if (range > 0) {
                        var ratio = Math.max(0.0, Math.min(1.0, thumb.y / range));
                        root.target.contentY = ratio * (root.target.contentHeight - root.target.height);
                    }
                }
            }
        }
    }
}
