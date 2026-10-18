import QtQuick
import QtQuick.Layouts

// System > About
ColumnLayout {
    Layout.fillWidth: true
    spacing: 0

    Text {
        text: "About"
        font.pixelSize: 24
        font.weight: Font.DemiBold
        color: SettingsTheme.text
        Layout.bottomMargin: 18
    }

    Text {
        text: "Device specifications"
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: SettingsTheme.muted
        Layout.bottomMargin: 8
    }

    SetCard {
        Layout.bottomMargin: 20

        SetRow {
            label: "Hostname"
            Text { text: SettingsState.sysHost; font.pixelSize: 13; color: SettingsTheme.text }
        }

        SetRow {
            label: "Processor"
            Text { text: SettingsState.sysCpu; font.pixelSize: 13; color: SettingsTheme.text }
        }

        SetRow {
            label: "Memory (RAM)"
            Text { text: SettingsState.sysMem; font.pixelSize: 13; color: SettingsTheme.text }
        }

        SetRow {
            label: "Primary display"
            isLast: true
            Text { text: SettingsState.displayInfo; font.pixelSize: 13; color: SettingsTheme.text }
        }
    }

    Text {
        text: "System software"
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: SettingsTheme.muted
        Layout.bottomMargin: 8
    }

    SetCard {
        SetRow {
            label: "Distribution"
            Text { text: "DssOS 2.4 (Black Edition)"; font.pixelSize: 13; color: SettingsTheme.accent }
        }

        SetRow {
            label: "Kernel version"
            Text { text: SettingsState.sysKernel; font.pixelSize: 13; color: SettingsTheme.text }
        }

        SetRow {
            label: "Compositor & Shell"
            Text { text: "Wayfire + Quickshell (Low-Spec Profile)"; font.pixelSize: 13; color: SettingsTheme.text }
        }

        SetRow {
            label: "Session uptime"
            isLast: true
            Text { text: SettingsState.sysUptime; font.pixelSize: 13; color: SettingsTheme.muted }
        }
    }
}
