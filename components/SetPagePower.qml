import QtQuick
import QtQuick.Layouts

// System > Power & battery
ColumnLayout {
    Layout.fillWidth: true
    spacing: 0

    Text {
        text: "Power & battery"
        font.pixelSize: 24
        font.weight: Font.DemiBold
        color: SettingsTheme.text
        Layout.bottomMargin: 18
    }

    Text {
        text: "Battery status"
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: SettingsTheme.muted
        Layout.bottomMargin: 8
    }

    SetCard {
        Layout.bottomMargin: 20

        SetRow {
            label: "Charge level: 84%"
            hint: "Discharging • Estimated 5 hr 20 min remaining"
            Rectangle {
                width: 120
                height: 10
                color: SettingsTheme.control
                border.width: 1
                border.color: SettingsTheme.edge
                Rectangle {
                    width: Math.round(parent.width * 0.84)
                    height: parent.height
                    color: SettingsTheme.accent
                }
            }
        }

        SetRow {
            label: "Power mode"
            hint: "Optimize CPU governor for battery life or responsiveness"
            stacked: true
            isLast: true
            SetRadio {
                options: ["Power Saver", "Balanced", "Performance"]
                current: 1
            }
        }
    }

    Text {
        text: "Screen & sleep"
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: SettingsTheme.muted
        Layout.bottomMargin: 8
    }

    SetCard {
        SetRow {
            label: "Turn off screen on battery"
            SetDropdown {
                options: ["2 minutes", "5 minutes", "10 minutes", "Never"]
                current: 1
            }
        }

        SetRow {
            label: "Suspend when plugged in"
            SetDropdown {
                options: ["15 minutes", "30 minutes", "1 hour", "Never"]
                current: 2
            }
        }

        SetRow {
            label: "Laptop lid close action"
            isLast: true
            SetDropdown {
                options: ["Suspend", "Lock screen", "Do nothing"]
                current: 0
            }
        }
    }
}
