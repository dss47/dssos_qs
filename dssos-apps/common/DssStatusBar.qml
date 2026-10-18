import QtQuick
import QtQuick.Layouts
import "."

Rectangle {
    id: root
    height: Theme.statusBarHeight
    color: Theme.status

    property string leftText: ""
    property string middleText: ""
    property string rightText: ""

    // 1px top divider
    Rectangle {
        width: parent.width
        height: 1
        anchors.top: parent.top
        color: Theme.divider
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 16

        Text {
            text: root.leftText
            color: Theme.muted
            font.pixelSize: Theme.fontSizeHeader
            font.family: Theme.fontFamily
            visible: root.leftText !== ""
        }

        Text {
            text: root.middleText
            color: Theme.muted
            font.pixelSize: Theme.fontSizeHeader
            font.family: Theme.fontFamily
            visible: root.middleText !== ""
        }

        Item { Layout.fillWidth: true }

        Text {
            text: root.rightText
            color: Theme.muted
            font.pixelSize: Theme.fontSizeHeader
            font.family: Theme.fontFamily
            visible: root.rightText !== ""
        }
    }
}
