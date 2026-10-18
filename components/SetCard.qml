import QtQuick
import QtQuick.Layouts

// Grouped settings card: 1px outer edge border, card bg, 1px dividers between rows.
Rectangle {
    id: root
    default property alias rows: col.children

    Layout.fillWidth: true
    color: SettingsTheme.card
    border.width: 1
    border.color: SettingsTheme.edge

    implicitWidth: col.implicitWidth + 2
    implicitHeight: col.implicitHeight + 2

    ColumnLayout {
        id: col
        anchors {
            fill: parent
            margins: 1
        }
        spacing: 0
    }
}
