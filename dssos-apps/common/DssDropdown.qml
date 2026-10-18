import QtQuick
import QtQuick.Layouts
import "."

// Universal inline option selector for low-spec systems: zero popup overhead, instant cycling.
Rectangle {
    id: root
    property var options: []
    property int current: 0
    signal activated(int index)

    implicitWidth: Math.max(150, labelText.implicitWidth + 56)
    implicitHeight: 30
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: 30
    Layout.alignment: Qt.AlignVCenter

    color: Theme.control
    border.width: 1
    border.color: Theme.edge

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // Previous button square
        Rectangle {
            Layout.preferredWidth: 28
            Layout.fillHeight: true
            color: prevArea.containsMouse ? (prevArea.pressed ? Theme.selected : Theme.hover) : "transparent"
            border.width: prevArea.containsMouse ? 1 : 0
            border.color: Theme.accent

            Text {
                anchors.centerIn: parent
                text: "‹"
                font.pixelSize: 16
                color: prevArea.containsMouse ? Theme.accent : Theme.muted
            }

            MouseArea {
                id: prevArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.options.length === 0) return;
                    root.current = (root.current - 1 + root.options.length) % root.options.length;
                    root.activated(root.current);
                }
            }
        }

        Rectangle {
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            color: Theme.edge
        }

        // Current option label (click to advance)
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Text {
                id: labelText
                anchors.centerIn: parent
                text: (root.options && root.options.length > 0 && root.current >= 0 && root.current < root.options.length)
                      ? root.options[root.current] : "—"
                font.pixelSize: Theme.fontSizeNormal
                font.family: Theme.fontFamily
                color: Theme.text
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.options.length === 0) return;
                    root.current = (root.current + 1) % root.options.length;
                    root.activated(root.current);
                }
            }
        }

        Rectangle {
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            color: Theme.edge
        }

        // Next button square
        Rectangle {
            Layout.preferredWidth: 28
            Layout.fillHeight: true
            color: nextArea.containsMouse ? (nextArea.pressed ? Theme.selected : Theme.hover) : "transparent"
            border.width: nextArea.containsMouse ? 1 : 0
            border.color: Theme.accent

            Text {
                anchors.centerIn: parent
                text: "›"
                font.pixelSize: 16
                color: nextArea.containsMouse ? Theme.accent : Theme.muted
            }

            MouseArea {
                id: nextArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.options.length === 0) return;
                    root.current = (root.current + 1) % root.options.length;
                    root.activated(root.current);
                }
            }
        }
    }
}
