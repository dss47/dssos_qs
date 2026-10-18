import QtQuick
import QtQuick.Layouts

// Personalization > Background
ColumnLayout {
    Layout.fillWidth: true
    spacing: 0

    Text {
        text: "Background"
        font.pixelSize: 24
        font.weight: Font.DemiBold
        color: SettingsTheme.text
        Layout.bottomMargin: 18
    }

    Text {
        text: "Desktop surface"
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: SettingsTheme.muted
        Layout.bottomMargin: 8
    }

    SetCard {
        Layout.bottomMargin: 20

        SetRow {
            label: "Background mode"
            hint: "Solid color uses zero VRAM texture memory on low-end laptops"
            stacked: true
            SetRadio {
                options: ["Solid color (Zero VRAM)", "Static image"]
                current: 0
            }
        }

        SetRow {
            label: "Solid preset"
            stacked: true
            isLast: true
            SetRadio {
                options: ["Pure Black (#000000)", "Carbon (#0a0a0a)", "Deep Forest (#06120c)", "Slate (#0d1117)"]
                current: 0
            }
        }
    }

    Text {
        text: "Image fit"
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: SettingsTheme.muted
        Layout.bottomMargin: 8
    }

    SetCard {
        SetRow {
            label: "Scaling mode"
            isLast: true
            SetDropdown {
                options: ["Fill", "Fit", "Center", "Tile"]
                current: 0
            }
        }
    }
}
