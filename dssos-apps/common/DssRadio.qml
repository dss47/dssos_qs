import QtQuick
import QtQuick.Layouts
import "."

// Universal square radio group for DssOS applications.
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
            color: isCurrent ? Theme.selected : (optHover.containsMouse ? Theme.hover : Theme.control)
            border.width: 1
            border.color: isCurrent ? Theme.accent : Theme.edge

            RowLayout {
                id: optRow
                anchors.centerIn: parent
                spacing: 8

                Rectangle {
                    Layout.preferredWidth: 12
                    Layout.preferredHeight: 12
                    color: parent.parent.isCurrent ? Theme.accent : "transparent"
                    border.width: parent.parent.isCurrent ? 0 : 1
                    border.color: Theme.muted
                }

                Text {
                    text: modelData
                    font.pixelSize: Theme.fontSizeNormal
                    font.family: Theme.fontFamily
                    color: parent.parent.isCurrent ? Theme.text : Theme.muted
                }
            }

            MouseArea {
                id: optHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.current = index;
                    root.selected(index);
                }
            }
        }
    }
}
