import QtQuick
import Quickshell
import Quickshell.Widgets
import "."

Rectangle {
    id: root
    width: 30
    height: 30
    color: root.active ? Theme.selected : (mouseArea.containsMouse ? Theme.cardHover : Theme.card)

    property string iconName: ""
    property color iconColor: root.active ? Theme.accent : Theme.muted
    property bool active: false
    property string tooltip: ""

    signal clicked()

    IconImage {
        anchors.centerIn: parent
        width: 16
        height: 16
        source: root.iconName ? "image://icon/" + root.iconName : ""
        visible: root.iconName !== ""
    }

    // 2px green bottom accent line when active
    Rectangle {
        height: 2
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        color: Theme.accent
        visible: root.active
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
