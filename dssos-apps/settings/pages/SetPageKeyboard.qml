import settings
import QtQuick
import QtQuick.Layouts

// Input > Keyboard
ColumnLayout {
    Layout.fillWidth: true
    spacing: 0

    Text {
        text: "Keyboard"
        font.pixelSize: 24
        font.weight: Font.DemiBold
        color: SettingsTheme.text
        Layout.bottomMargin: 18
    }

    Text {
        text: "Layout & input"
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: SettingsTheme.muted
        Layout.bottomMargin: 8
    }

    SetCard {
        Layout.bottomMargin: 20

        SetRow {
            label: "Keyboard layout"
            hint: "Active XKB layout for physical keyboard"
            stacked: true
            SetRadio {
                // Same story as the accent picker: hardcoded current, no
                // onSelected. kbLayout was saved to JSON and read back, but
                // nothing ever told X about it.
                options: ["English (US)", "English (UK)", "French (AZERTY)", "German (QWERTZ)"]
                current: {
                    const order = ["us", "gb", "fr", "de"];
                    const i = order.indexOf(SettingsState.kbLayout);
                    return i === -1 ? 0 : i;
                }
                onSelected: (idx) => {
                    const order = ["us", "gb", "fr", "de"];
                    if (idx >= 0 && idx < order.length) {
                        SettingsState.kbLayout = order[idx];
                        SettingsState.applyKeyboardLayout(order[idx]);
                    }
                }
            }
        }

        SetRow {
            label: "Caps Lock behavior"
            isLast: true
            SetDropdown {
                options: ["Standard Caps Lock", "Map to Escape", "Map to Ctrl"]
                current: 0
            }
        }
    }

    Text {
        text: "Key repeat"
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: SettingsTheme.muted
        Layout.bottomMargin: 8
    }

    SetCard {
        SetRow {
            label: "Repeat delay"
            hint: "Wait time before held key starts repeating"
            SetSlider {
                id: delaySlider
                from: 150
                to: 800
                value: SettingsState.kbRepeatDelay
                onMoved: (v) => SettingsState.kbRepeatDelay = Math.round(v)
            }
            Text {
                text: Math.round(delaySlider.value) + " ms"
                font.pixelSize: 13
                color: SettingsTheme.text
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 52
            }
        }

        SetRow {
            label: "Repeat rate"
            hint: "Characters generated per second while held"
            isLast: true
            SetSlider {
                id: rateSlider
                from: 10
                to: 80
                value: SettingsState.kbRepeatRate
                onMoved: (v) => SettingsState.kbRepeatRate = Math.round(v)
            }
            Text {
                text: Math.round(rateSlider.value) + "/s"
                font.pixelSize: 13
                color: SettingsTheme.text
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 52
            }
        }
    }
}
