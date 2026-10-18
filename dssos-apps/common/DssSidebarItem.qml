import QtQuick
import QtQuick.Layouts
import "."

// Universal sidebar navigation item: 3px active accent indicator, hover highlight, elided text.
Rectangle {
    id: root
    property string label: ""
    property bool selected: false
    signal clicked

    implicitWidth: 229
    implicitHeight: 38
    Layout.fillWidth: true
    Layout.preferredHeight: 38

    color: root.selected ? Theme.selected : (hoverArea.containsMouse ? Theme.hover : "transparent")

    Rectangle {
        visible: root.selected
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
        }
        width: 3
        color: Theme.accent
    }

    Text {
        anchors {
            left: parent.left
            leftMargin: 18
            right: parent.right
            rightMargin: 12
            verticalCenter: parent.verticalCenter
        }
        text: root.label
        font.pixelSize: Theme.fontSizeNormal
        font.family: Theme.fontFamily
        font.weight: root.selected ? Font.Medium : Font.Normal
        color: root.selected ? Theme.text : (hoverArea.containsMouse ? "#cccccc" : Theme.muted)
        elide: Text.ElideRight
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
