import QtQuick
import QtQuick.Layouts

// System > Multitasking
ColumnLayout {
    Layout.fillWidth: true
    spacing: 0

    Text {
        text: "Multitasking"
        font.pixelSize: 24
        font.weight: Font.DemiBold
        color: SettingsTheme.text
        Layout.bottomMargin: 18
    }

    Text {
        text: "Window snapping"
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: SettingsTheme.muted
        Layout.bottomMargin: 8
    }

    SetCard {
        Layout.bottomMargin: 20

        SetRow {
            label: "Snap windows"
            hint: "Automatically tile windows when dragged to screen edges or corners"
            SetToggle { on: true }
        }

        SetRow {
            label: "Edge snap threshold"
            hint: "Distance in pixels from screen edge to trigger tiling preview"
            isLast: true
            SetDropdown {
                options: ["8 px", "16 px", "24 px"]
                current: 1
            }
        }
    }

    Text {
        text: "Low-end hardware optimizations"
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: SettingsTheme.muted
        Layout.bottomMargin: 8
    }

    SetCard {
        SetRow {
            label: "Direct scanout for fullscreen apps"
            hint: "Bypass compositor rendering when a window is fullscreen"
            SetToggle { on: true }
        }

        SetRow {
            label: "Alt+Tab switcher style"
            hint: "Simple list avoids live window texture sampling on integrated GPUs"
            isLast: true
            SetDropdown {
                options: ["Compact List (Fast)", "Icon Grid"]
                current: 0
            }
        }
    }
}
