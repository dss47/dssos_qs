import QtQuick
import QtQuick.Layouts

// 44x22 square toggle with explicit implicitWidth/Height so Layouts never collapse it.
Rectangle {
    id: root
    property bool on: false
    signal toggled(bool on)

    implicitWidth: 44
    implicitHeight: 22
    Layout.preferredWidth: 44
    Layout.preferredHeight: 22
    Layout.alignment: Qt.AlignVCenter

    color: root.on ? SettingsTheme.accent : (togHover.containsMouse ? SettingsTheme.controlHover : SettingsTheme.control)
    border.width: root.on ? 0 : 1
    border.color: togHover.containsMouse ? SettingsTheme.accent : SettingsTheme.muted

    Rectangle {
        x: root.on ? (root.width - width - 4) : 4
        anchors.verticalCenter: parent.verticalCenter
        width: 14
        height: 14
        color: root.on ? SettingsTheme.accentDark : SettingsTheme.muted
    }

    MouseArea {
        id: togHover
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            root.on = !root.on;
            root.toggled(root.on);
        }
    }
}
