import QtQuick
import QtQuick.Layouts

// System > Clipboard
ColumnLayout {
    Layout.fillWidth: true
    spacing: 0

    Text {
        text: "Clipboard"
        font.pixelSize: 24
        font.weight: Font.DemiBold
        color: SettingsTheme.text
        Layout.bottomMargin: 18
    }

    Text {
        text: "History & persistence"
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: SettingsTheme.muted
        Layout.bottomMargin: 8
    }

    SetCard {
        SetRow {
            label: "Clipboard history"
            hint: "Save recent copied text snippets for Super+V quick paste"
            SetToggle { on: true }
        }

        SetRow {
            label: "Maximum history items"
            hint: "Lower limits keep memory footprint minimal"
            SetDropdown {
                options: ["15 items", "25 items", "50 items"]
                current: 1
            }
        }

        SetRow {
            label: "Ignore large images"
            hint: "Skip bitmap buffers larger than 2 MB to save RAM"
            SetToggle { on: true }
        }

        SetRow {
            label: "Clear clipboard on sign out"
            isLast: true
            SetToggle { on: false }
        }
    }
}
