import QtQuick
import QtQuick.Layouts
import "."

// Universal DssRow: Works for key-value rows (Tasks overview, system info)
// and interactive controls (Settings cards, sliders, toggles).
ColumnLayout {
    id: root

    property string label: ""
    property string hint: ""
    property string value: ""
    property int labelWidth: 150
    property bool isLast: false
    property bool showDivider: !isLast
    property bool stacked: false
    default property alias control: ctrlBox.data

    Layout.fillWidth: true
    spacing: 0

    GridLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 16
        Layout.rightMargin: 16
        Layout.topMargin: 12
        Layout.bottomMargin: 12
        columns: root.stacked ? 1 : 2
        rowSpacing: root.stacked ? 10 : 0
        columnSpacing: 16

        // Label / Hint column
        ColumnLayout {
            Layout.fillWidth: (root.value !== "" && !root.stacked) ? false : true
            Layout.preferredWidth: (root.value !== "" && !root.stacked) ? root.labelWidth : -1
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            Text {
                visible: root.label !== ""
                text: root.label
                font.pixelSize: Theme.fontSizeNormal
                font.family: Theme.fontFamily
                font.weight: root.hint !== "" ? Font.Medium : Font.Normal
                color: (root.value !== "" && root.hint === "") ? Theme.muted : Theme.text
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }

            Text {
                visible: root.hint !== ""
                text: root.hint
                font.pixelSize: Theme.fontSizeSmall
                font.family: Theme.fontFamily
                color: Theme.muted
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
        }

        // Control / Value container
        RowLayout {
            id: ctrlBox
            spacing: 10
            Layout.fillWidth: root.stacked || root.value !== ""
            Layout.alignment: root.stacked ? Qt.AlignLeft : (root.value !== "" ? Qt.AlignLeft : (Qt.AlignRight | Qt.AlignVCenter))

            Text {
                id: valText
                visible: root.value !== ""
                text: root.value
                color: Theme.text
                font.pixelSize: Theme.fontSizeNormal
                font.family: Theme.fontFamily
                Layout.fillWidth: true
                wrapMode: Text.Wrap
            }
        }
    }

    Rectangle {
        visible: root.showDivider
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        height: 1
        color: Theme.divider
    }
}
