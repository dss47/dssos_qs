import QtQuick
import QtQuick.Layouts

// Personalization > Colors
ColumnLayout {
    Layout.fillWidth: true
    spacing: 0

    Text {
        text: "Colors"
        font.pixelSize: 24
        font.weight: Font.DemiBold
        color: SettingsTheme.text
        Layout.bottomMargin: 18
    }

    Text {
        text: "Theme & accent"
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: SettingsTheme.muted
        Layout.bottomMargin: 8
    }

    SetCard {
        Layout.bottomMargin: 20

        SetRow {
            label: "Skin mode"
            hint: "OLED pitch-black theme with high-contrast square edges"
            SetDropdown {
                options: ["Black (Default)", "Dark Gray"]
                current: 0
            }
        }

        SetRow {
            label: "Accent color"
            hint: "Applied to active indicators, sliders, and toggles"
            stacked: true
            isLast: true
            SetRadio {
                options: ["Emerald (#34c77b)", "Cyan (#29b6f6)", "Amber (#ffb300)", "Crimson (#ef5350)", "Monochrome (#e0e0e0)"]
                current: 0
            }
        }
    }

    Text {
        text: "Shell geometry"
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: SettingsTheme.muted
        Layout.bottomMargin: 8
    }

    SetCard {
        SetRow {
            label: "Taskbar height"
            SetSlider {
                id: barSlider
                from: 28
                to: 48
                value: SettingsState.barHeight
                onMoved: (v) => SettingsState.barHeight = Math.round(v)
            }
            Text {
                text: Math.round(barSlider.value) + " px"
                font.pixelSize: 13
                color: SettingsTheme.text
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 44
            }
        }

        SetRow {
            label: "Flyout edge gap"
            isLast: true
            SetSlider {
                id: gapSlider
                from: 0
                to: 20
                value: SettingsState.flyoutGap
                onMoved: (v) => SettingsState.flyoutGap = Math.round(v)
            }
            Text {
                text: Math.round(gapSlider.value) + " px"
                font.pixelSize: 13
                color: SettingsTheme.text
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 44
            }
        }
    }
}
