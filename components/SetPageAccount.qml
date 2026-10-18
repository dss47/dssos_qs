import QtQuick
import QtQuick.Layouts

// Accounts > Your info
ColumnLayout {
    Layout.fillWidth: true
    spacing: 0

    Text {
        text: "Your info"
        font.pixelSize: 24
        font.weight: Font.DemiBold
        color: SettingsTheme.text
        Layout.bottomMargin: 18
    }

    Text {
        text: "Current user"
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: SettingsTheme.muted
        Layout.bottomMargin: 8
    }

    SetCard {
        Layout.bottomMargin: 20

        SetRow {
            label: "dssos"
            hint: "Administrator (wheel, video, audio, input) • UID 1000"
            Rectangle {
                width: 36
                height: 36
                color: SettingsTheme.selected
                border.width: 1
                border.color: SettingsTheme.accent
                Text {
                    anchors.centerIn: parent
                    text: "DS"
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    color: SettingsTheme.accent
                }
            }
        }

        SetRow {
            label: "Login shell"
            isLast: true
            SetDropdown {
                options: ["/bin/bash", "/bin/zsh", "/usr/bin/fish"]
                current: 1
            }
        }
    }

    Text {
        text: "Session & lock"
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: SettingsTheme.muted
        Layout.bottomMargin: 8
    }

    SetCard {
        SetRow {
            label: "Automatic login on boot"
            hint: "Skip greetd prompt on startup"
            SetToggle { on: false }
        }

        SetRow {
            label: "Require password after suspend"
            isLast: true
            SetToggle { on: true }
        }
    }
}
