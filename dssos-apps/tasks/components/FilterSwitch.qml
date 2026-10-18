import QtQuick
import tasks

Row {
    id: root
    height: 30
    spacing: 0

    property int currentIndex: 0 // 0: All, 1: Apps, 2: Background
    signal filterChanged(int index)

    readonly property var labels: ["All", "Apps", "Background"]

    Repeater {
        model: root.labels

        Rectangle {
            id: itemRect
            height: 30
            width: itemText.implicitWidth + 24
            color: root.currentIndex === index ? Theme.selected : (itemMouse.containsMouse ? Theme.tileHover : Theme.card)

            Text {
                id: itemText
                anchors.centerIn: parent
                text: modelData
                color: root.currentIndex === index ? Theme.text : Theme.muted
                font.pixelSize: Theme.fontSizeNormal
                font.family: Theme.fontFamily
            }

            // 2px green bottom indicator when active
            Rectangle {
                height: 2
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                color: Theme.accent
                visible: root.currentIndex === index
            }

            MouseArea {
                id: itemMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.currentIndex = index;
                    root.filterChanged(index);
                }
            }
        }
    }
}
