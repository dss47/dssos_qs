import settings
import QtQuick
import QtQuick.Layouts

// Input > Mouse
ColumnLayout {
    Layout.fillWidth: true
    spacing: 0

    Text {
        text: "Mouse & touchpad"
        font.pixelSize: 24
        font.weight: Font.DemiBold
        color: SettingsTheme.text
        Layout.bottomMargin: 18
    }

    Text {
        text: "Pointer"
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: SettingsTheme.muted
        Layout.bottomMargin: 8
    }

    SetCard {
        Layout.bottomMargin: 20

        SetRow {
            label: "Primary button"
            SetDropdown {
                options: ["Left", "Right"]
                current: 0
            }
        }

        SetRow {
            label: "Pointer speed"
            SetSlider {
                id: spdSlider
                from: -100
                to: 100
                value: SettingsState.mouseSpeed * 100
                onMoved: (v) => SettingsState.mouseSpeed = v / 100.0
            }
            Text {
                text: (spdSlider.value / 100.0).toFixed(2)
                font.pixelSize: 13
                color: SettingsTheme.text
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 44
            }
        }

        SetRow {
            label: "Acceleration profile"
            hint: "Flat profile provides raw 1:1 cursor movement"
            stacked: true
            isLast: true
            SetRadio {
                options: ["Adaptive (Default)", "Flat (Raw)"]
                current: 0
            }
        }
    }

    Text {
        text: "Touchpad"
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: SettingsTheme.muted
        Layout.bottomMargin: 8
    }

    SetCard {
        SetRow {
            label: "Tap to click"
            hint: "Single-finger tap registers as primary click"
            SetToggle {
                on: SettingsState.touchpadTap
                onToggled: (v) => SettingsState.touchpadTap = v
            }
        }

        SetRow {
            label: "Natural scrolling"
            hint: "Content moves in the direction of your fingers"
            SetToggle {
                on: SettingsState.touchpadNatural
                onToggled: (v) => SettingsState.touchpadNatural = v
            }
        }

        SetRow {
            label: "Disable while typing"
            hint: "Prevent accidental palm touches while using keyboard"
            isLast: true
            SetToggle { on: true }
        }
    }
}
