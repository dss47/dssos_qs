import QtQuick
import QtQuick.Layouts

// Lightweight inline cycle selector for low-end laptops.
// Avoids popup window creation or Flickable clipping while providing instant option switching.
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

    color: SettingsTheme.control
    border.width: 1
    border.color: SettingsTheme.edge

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // Previous button square
        Rectangle {
            Layout.preferredWidth: 28
            Layout.fillHeight: true
            color: prevArea.containsMouse ? (prevArea.pressed ? SettingsTheme.selected : SettingsTheme.hover) : "transparent"
            border.width: prevArea.containsMouse ? 1 : 0
            border.color: SettingsTheme.accent

            Text {
                anchors.centerIn: parent
                text: "‹"
                font.pixelSize: 16
                color: prevArea.containsMouse ? SettingsTheme.accent : SettingsTheme.muted
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
            color: SettingsTheme.edge
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
                font.pixelSize: 13
                color: SettingsTheme.text
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
            color: SettingsTheme.edge
        }

        // Next button square
        Rectangle {
            Layout.preferredWidth: 28
            Layout.fillHeight: true
            color: nextArea.containsMouse ? (nextArea.pressed ? SettingsTheme.selected : SettingsTheme.hover) : "transparent"
            border.width: nextArea.containsMouse ? 1 : 0
            border.color: SettingsTheme.accent

            Text {
                anchors.centerIn: parent
                text: "›"
                font.pixelSize: 16
                color: nextArea.containsMouse ? SettingsTheme.accent : SettingsTheme.muted
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
