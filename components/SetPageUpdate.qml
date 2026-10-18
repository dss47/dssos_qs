import QtQuick
import QtQuick.Layouts

// Updates > DssOS Update
ColumnLayout {
    Layout.fillWidth: true
    spacing: 0

    Text {
        text: "DssOS Update"
        font.pixelSize: 24
        font.weight: Font.DemiBold
        color: SettingsTheme.text
        Layout.bottomMargin: 18
    }

    Text {
        text: "System status"
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: SettingsTheme.muted
        Layout.bottomMargin: 8
    }

    SetCard {
        Layout.bottomMargin: 20

        SetRow {
            label: "Your system is up to date"
            hint: "Last checked today at 16:30 • Channel: dssos-stable"
            Rectangle {
                width: 116
                height: 30
                color: chkHover.containsMouse ? SettingsTheme.hover : SettingsTheme.control
                border.width: 1
                border.color: chkHover.containsMouse ? SettingsTheme.accent : SettingsTheme.edge

                Text {
                    anchors.centerIn: parent
                    text: "Check now"
                    font.pixelSize: 13
                    color: SettingsTheme.text
                }

                MouseArea {
                    id: chkHover
                    anchors.fill: parent
                    hoverEnabled: true
                }
            }
        }

        SetRow {
            label: "Update channel"
            stacked: true
            isLast: true
            SetRadio {
                options: ["Stable (Recommended)", "Testing"]
                current: 0
            }
        }
    }

    Text {
        text: "Background updates"
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: SettingsTheme.muted
        Layout.bottomMargin: 8
    }

    SetCard {
        SetRow {
            label: "Check for updates automatically"
            hint: "Run lightweight repository sync once per week"
            SetToggle { on: true }
        }

        SetRow {
            label: "Pause updates on metered or battery power"
            isLast: true
            SetToggle { on: true }
        }
    }
}
