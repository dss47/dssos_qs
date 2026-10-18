import QtQuick
import QtQuick.Layouts
import "."

// Universal navigation rail button with active accent edge and icon.
Rectangle {
    id: root
    property string iconGlyph: ""
    property bool selected: false
    signal clicked

    implicitWidth: 63
    implicitHeight: 48
    Layout.preferredWidth: 63
    Layout.preferredHeight: 48

    color: root.selected ? Theme.selected : (hoverArea.containsMouse ? Theme.hover : "transparent")

    Rectangle {
        visible: root.selected
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
            topMargin: 10
            bottomMargin: 10
        }
        width: 3
        color: Theme.accent
    }

    Text {
        anchors.centerIn: parent
        text: root.iconGlyph
        font.family: "JetBrains Mono Nerd Font"
        font.pixelSize: 20
        color: root.selected ? Theme.accent : "#ffffff"
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
