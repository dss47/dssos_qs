import settings
import QtQuick
import QtQuick.Layouts

// Page list item: pure declarative color binding so selection state never gets stuck.
Rectangle {
    id: root
    property string label: ""
    property bool selected: false
    signal clicked

    implicitWidth: 229
    implicitHeight: 38
    Layout.fillWidth: true
    Layout.preferredHeight: 38

    color: root.selected ? SettingsTheme.selected : (hoverArea.containsMouse ? SettingsTheme.hover : "transparent")

    Rectangle {
        visible: root.selected
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
        }
        width: 3
        color: SettingsTheme.accent
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
        font.pixelSize: 14
        font.weight: root.selected ? Font.Medium : Font.Normal
        color: root.selected ? SettingsTheme.text : (hoverArea.containsMouse ? "#cccccc" : SettingsTheme.muted)
        elide: Text.ElideRight
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
