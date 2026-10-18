import QtQuick
import QtQuick.Layouts

// 63x48 rail button with Nerd Font icon glyph (zero-cost text rendering).
Rectangle {
    id: root
    property string iconGlyph: ""
    property bool selected: false
    signal clicked

    implicitWidth: 63
    implicitHeight: 48
    Layout.preferredWidth: 63
    Layout.preferredHeight: 48

    color: root.selected ? SettingsTheme.selected : (hoverArea.containsMouse ? SettingsTheme.hover : "transparent")

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
        color: SettingsTheme.accent
    }

    Text {
        anchors.centerIn: parent
        text: root.iconGlyph
        font.family: "JetBrains Mono Nerd Font"
        font.pixelSize: 20
        color: root.selected ? SettingsTheme.accent : "#ffffff"
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
