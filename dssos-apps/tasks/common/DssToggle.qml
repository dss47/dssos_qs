import QtQuick
import QtQuick.Layouts
import "."

// Universal 44x22 square toggle switch for DssOS applications.
Rectangle {
    id: root
    property bool on: false
    signal toggled(bool on)

    implicitWidth: 44
    implicitHeight: 22
    Layout.preferredWidth: 44
    Layout.preferredHeight: 22
    Layout.alignment: Qt.AlignVCenter

    color: root.on ? Theme.accent : (togHover.containsMouse ? Theme.controlHover : Theme.control)
    border.width: root.on ? 0 : 1
    border.color: togHover.containsMouse ? Theme.accent : Theme.muted

    Rectangle {
        x: root.on ? (root.width - width - 4) : 4
        anchors.verticalCenter: parent.verticalCenter
        width: 14
        height: 14
        color: root.on ? Theme.accentDark : Theme.muted
    }

    MouseArea {
        id: togHover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.on = !root.on;
            root.toggled(root.on);
        }
    }
}
