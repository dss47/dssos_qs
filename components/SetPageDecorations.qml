import QtQuick
import QtQuick.Layouts

// Desktop > Decorations
ColumnLayout {
    Layout.fillWidth: true
    spacing: 0

    Text {
        text: "Decorations"
        font.pixelSize: 24
        font.weight: Font.DemiBold
        color: SettingsTheme.text
        Layout.bottomMargin: 18
    }

    Text {
        text: "Window borders & shadows"
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: SettingsTheme.muted
        Layout.bottomMargin: 8
    }

    SetCard {
        SetRow {
            label: "Corner style"
            hint: "Square corners eliminate alpha-mask clipping passes on integrated GPUs"
            SetDropdown {
                options: ["Square (0 px)", "Subtle (4 px)"]
                current: 0
            }
        }

        SetRow {
            label: "Active border thickness"
            SetDropdown {
                options: ["1 px", "2 px", "3 px"]
                current: 0
            }
        }

        SetRow {
            label: "Window drop shadows"
            hint: "Keep disabled on low-end laptops to save fill-rate bandwidth"
            SetToggle { on: false }
        }

        SetRow {
            label: "Background blur behind windows"
            hint: "Dual-Kawase blur shader (High GPU usage when enabled)"
            isLast: true
            SetToggle { on: false }
        }
    }
}
