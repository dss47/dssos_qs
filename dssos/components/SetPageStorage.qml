import QtQuick
import QtQuick.Layouts

// System > Storage
ColumnLayout {
    Layout.fillWidth: true
    spacing: 0

    Text {
        text: "Storage"
        font.pixelSize: 24
        font.weight: Font.DemiBold
        color: SettingsTheme.text
        Layout.bottomMargin: 18
    }

    Text {
        text: "Primary disk (/dev/nvme0n1p2)"
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: SettingsTheme.muted
        Layout.bottomMargin: 8
    }

    SetCard {
        Layout.bottomMargin: 20

        SetRow {
            label: "42.8 GB used of 256 GB"
            hint: "213.2 GB free • ext4 filesystem"
            stacked: true
            Rectangle {
                Layout.fillWidth: true
                height: 12
                color: SettingsTheme.control
                border.width: 1
                border.color: SettingsTheme.edge
                Rectangle {
                    width: Math.round(parent.width * 0.17)
                    height: parent.height
                    color: SettingsTheme.accent
                }
            }
        }

        SetRow {
            label: "System & packages"
            hint: "Core OS binaries, libraries, and kernel images"
            Text { text: "14.2 GB"; font.pixelSize: 13; color: SettingsTheme.text }
        }

        SetRow {
            label: "User home directory"
            hint: "Documents, projects, and local media"
            Text { text: "24.5 GB"; font.pixelSize: 13; color: SettingsTheme.text }
        }

        SetRow {
            label: "Package cache & logs"
            hint: "Pacman cache and systemd journal archives"
            isLast: true
            Text { text: "4.1 GB"; font.pixelSize: 13; color: SettingsTheme.muted }
        }
    }

    Text {
        text: "Maintenance"
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: SettingsTheme.muted
        Layout.bottomMargin: 8
    }

    SetCard {
        SetRow {
            label: "Auto-clean temporary files"
            hint: "Purge /tmp and old package archives older than 14 days"
            SetToggle { on: true }
        }

        SetRow {
            label: "SSD periodic TRIM"
            hint: "Weekly fstrim timer to sustain flash write speeds"
            isLast: true
            SetToggle { on: true }
        }
    }
}
