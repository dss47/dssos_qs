import QtQuick
import QtQuick.Layouts

// Privacy > General
ColumnLayout {
    Layout.fillWidth: true
    spacing: 0

    Text {
        text: "Privacy"
        font.pixelSize: 24
        font.weight: Font.DemiBold
        color: SettingsTheme.text
        Layout.bottomMargin: 18
    }

    Text {
        text: "Hardware permissions"
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: SettingsTheme.muted
        Layout.bottomMargin: 8
    }

    SetCard {
        Layout.bottomMargin: 20

        SetRow {
            label: "Camera access"
            hint: "Allow PipeWire video stream capture for applications"
            SetToggle { on: true }
        }

        SetRow {
            label: "Microphone access"
            hint: "Allow audio recording by non-system applications"
            SetToggle { on: true }
        }

        SetRow {
            label: "Screen sharing indicator"
            hint: "Always show green dot in taskbar when xdg-desktop-portal records screen"
            isLast: true
            SetToggle { on: true }
        }
    }

    Text {
        text: "Diagnostics"
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: SettingsTheme.muted
        Layout.bottomMargin: 8
    }

    SetCard {
        SetRow {
            label: "Crash report telemetry"
            hint: "DssOS collects zero telemetry by default"
            isLast: true
            SetToggle { on: false }
        }
    }
}
