import QtQuick
import tasks
import common

Item {
    id: root
    width: parent ? parent.width : Theme.sidebarWidth
    height: Theme.tileHeight

    property string label: ""
    property string value: ""
    property string subtitle: ""
    property color resourceColor: Theme.cpu
    property var history: []
    property bool isSelected: false

    signal clicked()

    Rectangle {
        id: bgRect
        anchors.fill: parent
        color: root.isSelected ? Theme.selected : (mouseArea.containsMouse ? Theme.tileHover : "transparent")

        // 3px green accent bar on the left when selected
        Rectangle {
            id: accentBar
            width: 3
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            color: Theme.accent
            visible: root.isSelected
        }

        // 1px divider at the bottom
        Rectangle {
            width: parent.width
            height: 1
            anchors.bottom: parent.bottom
            color: Theme.divider
        }

        // Content
        Column {
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.top: parent.top
            anchors.topMargin: 12
            anchors.right: parent.right
            anchors.rightMargin: 14
            spacing: 2

            Text {
                text: root.label
                color: Theme.muted
                font.pixelSize: Theme.fontSizeSmall
                font.family: Theme.fontFamily
            }

            Text {
                text: root.value
                color: Theme.text
                font.pixelSize: Theme.fontSizeValue
                font.weight: Font.Medium
                font.family: Theme.fontFamily
            }

            Text {
                text: root.subtitle
                color: Theme.muted
                font.pixelSize: Theme.fontSizeSmall
                font.family: Theme.fontFamily
                elide: Text.ElideRight
                width: parent.width
            }
        }

        // Sparkline graph
        Sparkline {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 38
            strokeColor: root.resourceColor
            points: root.history
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.clicked()
        }
    }
}
