import QtQuick
import QtQuick.Layouts

// Time & language > Date & time
ColumnLayout {
    Layout.fillWidth: true
    spacing: 0

    Text {
        text: "Date & time"
        font.pixelSize: 24
        font.weight: Font.DemiBold
        color: SettingsTheme.text
        Layout.bottomMargin: 18
    }

    Text {
        text: "Clock synchronization"
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: SettingsTheme.muted
        Layout.bottomMargin: 8
    }

    SetCard {
        Layout.bottomMargin: 20

        SetRow {
            label: "Set time automatically (NTP)"
            hint: "Synchronize clock via systemd-timesyncd"
            SetToggle { on: true }
        }

        SetRow {
            label: "Use 24-hour clock format"
            hint: "Display 16:40 instead of 4:40 PM in taskbar"
            SetToggle { on: true }
        }

        SetRow {
            label: "Show seconds in taskbar clock"
            hint: "Disabling seconds avoids 1 Hz bar redraws on battery"
            SetToggle { on: false }
        }

        SetRow {
            label: "Time zone"
            isLast: true
            SetDropdown {
                options: ["UTC+00:00", "Africa/Casablanca", "Europe/Paris", "America/New_York"]
                current: 1
            }
        }
    }
}
