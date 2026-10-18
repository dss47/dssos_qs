import QtQuick
import QtQuick.Layouts
import "."

// Universal DssCard: 1px border, Theme.card background, 0px radius.
// Automatically stacks child items or rows vertically.
ColumnLayout {
    id: root
    property string title: ""
    default property alias rows: col.data

    Layout.fillWidth: true
    spacing: 8

    Text {
        text: root.title
        color: Theme.muted
        font.pixelSize: Theme.fontSizeSmall
        font.weight: Font.DemiBold
        font.family: Theme.fontFamily
        visible: root.title !== ""
        Layout.leftMargin: 2
    }

    Rectangle {
        Layout.fillWidth: true
        color: Theme.card
        border.width: 1
        border.color: Theme.divider

        implicitHeight: col.implicitHeight + 2

        ColumnLayout {
            id: col
            anchors.fill: parent
            anchors.margins: 1
            spacing: 0
        }
    }
}
