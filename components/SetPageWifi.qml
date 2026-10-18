import QtQuick
import QtQuick.Layouts

// Network > Wi-Fi
ColumnLayout {
    Layout.fillWidth: true
    spacing: 0

    Text {
        text: "Wi-Fi"
        font.pixelSize: 24
        font.weight: Font.DemiBold
        color: SettingsTheme.text
        Layout.bottomMargin: 18
    }

    Text {
        text: "Wireless adapter (wlan0)"
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: SettingsTheme.muted
        Layout.bottomMargin: 8
    }

    SetCard {
        Layout.bottomMargin: 20

        SetRow {
            label: "Wi-Fi"
            hint: "Connected to DssOS-5G (192.168.1.42)"
            SetToggle {
                id: wifiToggle
                on: true
            }
        }

        SetRow {
            label: "Power saving on wireless card"
            hint: "Reduce Wi-Fi transmit power when idle on battery"
            isLast: true
            SetToggle { on: true }
        }
    }

    Text {
        text: "Available networks"
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: SettingsTheme.muted
        Layout.bottomMargin: 8
    }

    SetCard {
        SetRow {
            label: "DssOS-5G"
            hint: "Connected • WPA3 Personal • 5 GHz"
            Text { text: "96%"; font.pixelSize: 13; color: SettingsTheme.accent }
        }

        SetRow {
            label: "DssOS-Guest"
            hint: "Secured • WPA2 • 2.4 GHz"
            Text { text: "82%"; font.pixelSize: 13; color: SettingsTheme.muted }
        }

        SetRow {
            label: "Studio-Fiber-EXT"
            hint: "Secured • WPA2 • 5 GHz"
            isLast: true
            Text { text: "58%"; font.pixelSize: 13; color: SettingsTheme.muted }
        }
    }
}
