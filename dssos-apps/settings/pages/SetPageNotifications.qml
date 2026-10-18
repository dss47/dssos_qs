import settings
import QtQuick
import QtQuick.Layouts

// System > Notifications
ColumnLayout {
    Layout.fillWidth: true
    spacing: 0

    Text {
        text: "Notifications"
        font.pixelSize: 24
        font.weight: Font.DemiBold
        color: SettingsTheme.text
        Layout.bottomMargin: 18
    }

    Text {
        text: "Popup behavior"
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: SettingsTheme.muted
        Layout.bottomMargin: 8
    }

    SetCard {
        Layout.bottomMargin: 20

        SetRow {
            label: "Notifications"
            hint: "Show desktop banners from applications and system services"
            SetToggle {
                on: SettingsState.notificationsEnabled
                onToggled: (v) => SettingsState.notificationsEnabled = v
            }
        }

        SetRow {
            label: "Do Not Disturb"
            hint: "Silence all incoming banners and notification sounds"
            SetToggle {
                on: SettingsState.doNotDisturb
                onToggled: (v) => SettingsState.doNotDisturb = v
            }
        }

        SetRow {
            label: "Show on lock screen"
            hint: "Display notification details before signing in"
            SetToggle { on: false }
        }

        SetRow {
            label: "Banner timeout"
            hint: "Duration before popup banners automatically dismiss"
            isLast: true
            SetDropdown {
                options: ["3 seconds", "5 seconds", "10 seconds"]
                current: 1
            }
        }
    }

    Text {
        text: "System alerts"
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: SettingsTheme.muted
        Layout.bottomMargin: 8
    }

    SetCard {
        SetRow {
            label: "Low battery warning"
            hint: "Notify when battery drops below 15%"
            SetToggle { on: true }
        }

        SetRow {
            label: "USB device events"
            hint: "Show banner when external drives are mounted"
            isLast: true
            SetToggle { on: true }
        }
    }
}
