import QtQuick
import QtQuick.Layouts

// Card row: supports standard horizontal layout (label/hint left, control right)
// and stacked layout (`stacked: true` for full-width radio groups or custom controls).
ColumnLayout {
    id: root
    property string label: ""
    property string hint: ""
    property bool isLast: false
    property bool stacked: false
    default property alias control: ctrlBox.data

    Layout.fillWidth: true
    spacing: 0

    GridLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 16
        Layout.rightMargin: 16
        Layout.topMargin: 13
        Layout.bottomMargin: 13
        columns: root.stacked ? 1 : 2
        rowSpacing: root.stacked ? 10 : 0
        columnSpacing: 16

        ColumnLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 200
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            Text {
                visible: root.label !== ""
                text: root.label
                font.pixelSize: 14
                font.weight: Font.Medium
                color: SettingsTheme.text
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }

            Text {
                visible: root.hint !== ""
                text: root.hint
                font.pixelSize: 12
                color: SettingsTheme.muted
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
        }

        RowLayout {
            id: ctrlBox
            spacing: 10
            Layout.fillWidth: root.stacked
            Layout.alignment: root.stacked ? Qt.AlignLeft : (Qt.AlignRight | Qt.AlignVCenter)
        }
    }

    Rectangle {
        visible: !root.isLast
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        height: 1
        color: SettingsTheme.divider
    }
}
