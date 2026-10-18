import QtQuick
import QtQuick.Layouts

// Square radio button group in a wrapping Flow layout.
// Explicitly binds implicitHeight to childrenRect.height so ColumnLayout never clips wrapped lines.
Flow {
    id: root
    property var options: []
    property int current: 0
    signal selected(int index)

    Layout.fillWidth: true
    height: childrenRect.height
    spacing: 8

    Repeater {
        model: root.options
        Rectangle {
            readonly property bool isCurrent: index === root.current
            width: optRow.implicitWidth + 22
            height: 32
            color: isCurrent ? SettingsTheme.selected : (optHover.containsMouse ? SettingsTheme.hover : SettingsTheme.control)
            border.width: 1
            border.color: isCurrent ? SettingsTheme.accent : SettingsTheme.edge

            RowLayout {
                id: optRow
                anchors.centerIn: parent
                spacing: 8

                Rectangle {
                    Layout.preferredWidth: 12
                    Layout.preferredHeight: 12
                    color: parent.parent.isCurrent ? SettingsTheme.accent : "transparent"
                    border.width: parent.parent.isCurrent ? 0 : 1
                    border.color: SettingsTheme.muted
                }

                Text {
                    text: modelData
                    font.pixelSize: 13
                    color: parent.parent.isCurrent ? SettingsTheme.text : SettingsTheme.muted
                }
            }

            MouseArea {
                id: optHover
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    root.current = index;
                    root.selected(index);
                }
            }
        }
    }
}
