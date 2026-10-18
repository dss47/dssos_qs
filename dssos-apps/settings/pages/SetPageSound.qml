import settings
import QtQuick
import QtQuick.Layouts

// System > Sound
ColumnLayout {
    Layout.fillWidth: true
    spacing: 0

    Text {
        text: "Sound"
        font.pixelSize: 24
        font.weight: Font.DemiBold
        color: SettingsTheme.text
        Layout.bottomMargin: 18
    }

    Text {
        text: "Output"
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: SettingsTheme.muted
        Layout.bottomMargin: 8
    }

    SetCard {
        Layout.bottomMargin: 20

        SetRow {
            label: "Output device"
            hint: "Select where to play audio"
            SetDropdown {
                options: ["Built-in Speakers", "Headphones (3.5mm)", "HDMI Audio"]
                current: 0
            }
        }

        SetRow {
            label: "Master volume"
            SetSlider {
                id: volSlider
                from: 0
                to: 100
                value: SettingsState.volume
                onMoved: (v) => SettingsState.volume = Math.round(v)
            }
            Text {
                text: Math.round(volSlider.value) + "%"
                font.pixelSize: 13
                color: SettingsTheme.text
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 38
            }
        }

        SetRow {
            label: "Over-amplification"
            hint: "Allow volume boost above 100% for quiet media"
            isLast: true
            SetToggle { on: false }
        }
    }

    Text {
        text: "Input"
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: SettingsTheme.muted
        Layout.bottomMargin: 8
    }

    SetCard {
        SetRow {
            label: "Input device"
            SetDropdown {
                options: ["Internal Microphone", "Headset Mic"]
                current: 0
            }
        }

        SetRow {
            label: "Microphone level"
            SetSlider {
                id: micSlider
                from: 0
                to: 100
                value: SettingsState.micVolume
                onMoved: (v) => SettingsState.micVolume = Math.round(v)
            }
            Text {
                text: Math.round(micSlider.value) + "%"
                font.pixelSize: 13
                color: SettingsTheme.text
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 38
            }
        }

        SetRow {
            label: "Noise suppression"
            hint: "Lightweight voice filter optimized for low CPU usage"
            isLast: true
            SetToggle { on: true }
        }
    }
}
