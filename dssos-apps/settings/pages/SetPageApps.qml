import settings
import QtQuick
import QtQuick.Layouts

// Apps > Installed apps
ColumnLayout {
    Layout.fillWidth: true
    spacing: 0

    Text {
        text: "Installed apps"
        font.pixelSize: 24
        font.weight: Font.DemiBold
        color: SettingsTheme.text
        Layout.bottomMargin: 18
    }

    Text {
        text: "Default applications"
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: SettingsTheme.muted
        Layout.bottomMargin: 8
    }

    SetCard {
        Layout.bottomMargin: 20

        SetRow {
            label: "Terminal emulator"
            SetDropdown {
                options: ["Terminal (Foot)", "Kitty", "Alacritty"]
                current: 0
            }
        }

        SetRow {
            label: "Web browser"
            SetDropdown {
                options: ["Firefox", "Chromium", "Brave"]
                current: 0
            }
        }

        SetRow {
            label: "File manager"
            isLast: true
            SetDropdown {
                options: ["Thunar", "PCManFM", "Yazi (TUI)"]
                current: 0
            }
        }
    }

    Text {
        text: "System packages (6 installed)"
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: SettingsTheme.muted
        Layout.bottomMargin: 8
    }

    SetCard {
        SetRow {
            label: "Quickshell (dssos-shell)"
            hint: "0.1.0 • Core desktop shell & bar"
            Text { text: "18.4 MB"; font.pixelSize: 13; color: SettingsTheme.muted }
        }

        SetRow {
            label: "Wayfire Compositor"
            hint: "0.9.0 • Wayland window manager"
            Text { text: "14.1 MB"; font.pixelSize: 13; color: SettingsTheme.muted }
        }

        SetRow {
            label: "Foot Terminal"
            hint: "1.17.2 • Fast Wayland terminal"
            isLast: true
            Text { text: "2.6 MB"; font.pixelSize: 13; color: SettingsTheme.muted }
        }
    }
}
