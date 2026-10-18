import QtQuick
import QtQuick.Layouts
import tasks

Item {
    id: root
    width: parent ? parent.width : 200
    implicitHeight: Math.max(38, valText.implicitHeight + 20)

    property string label: ""
    property string value: ""
    property bool showDivider: true

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        spacing: 12

        Text {
            Layout.preferredWidth: 150
            Layout.alignment: Qt.AlignTop
            text: root.label
            color: Theme.muted
            font.pixelSize: Theme.fontSizeNormal
            font.family: Theme.fontFamily
        }

        Text {
            id: valText
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            text: root.value
            color: Theme.text
            font.pixelSize: Theme.fontSizeNormal
            font.family: Theme.fontFamily
            wrapMode: Text.Wrap
        }
    }

    Rectangle {
        width: parent.width
        height: 1
        anchors.bottom: parent.bottom
        color: Theme.divider
        visible: root.showDivider
    }
}
