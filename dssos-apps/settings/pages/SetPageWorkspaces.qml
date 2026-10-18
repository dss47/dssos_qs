import settings
import QtQuick
import QtQuick.Layouts

// Desktop > Workspaces
ColumnLayout {
    Layout.fillWidth: true
    spacing: 0

    Text {
        text: "Workspaces"
        font.pixelSize: 24
        font.weight: Font.DemiBold
        color: SettingsTheme.text
        Layout.bottomMargin: 18
    }

    Text {
        text: "Virtual desktops"
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: SettingsTheme.muted
        Layout.bottomMargin: 8
    }

    SetCard {
        Layout.bottomMargin: 20

        SetRow {
            label: "Workspace grid size"
            hint: "Number of fixed workspaces in the taskbar switcher"
            stacked: true
            SetRadio {
                options: ["4 Workspaces (1×4)", "6 Workspaces (2×3)", "9 Workspaces (3×3)"]
                current: 0
            }
        }

        SetRow {
            label: "Wrap around when switching"
            hint: "Moving past last workspace loops back to workspace 1"
            isLast: true
            SetToggle { on: true }
        }
    }

    Text {
        text: "Transitions & effects (Low-End GPU Tuning)"
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: SettingsTheme.muted
        Layout.bottomMargin: 8
    }

    SetCard {
        SetRow {
            label: "Workspace transition animations"
            hint: "Disable for instant zero-frame workspace switching"
            SetToggle {
                on: SettingsState.wfAnimate
                onToggled: (v) => SettingsState.wfAnimate = v
            }
        }

        SetRow {
            label: "Wobbly windows"
            hint: "Deform window mesh when dragging (Higher GPU cost)"
            SetToggle {
                on: SettingsState.wfWobbly
                onToggled: (v) => SettingsState.wfWobbly = v
            }
        }

        SetRow {
            label: "3D desktop cube"
            isLast: true
            SetToggle {
                on: SettingsState.wfCube
                onToggled: (v) => SettingsState.wfCube = v
            }
        }
    }
}
