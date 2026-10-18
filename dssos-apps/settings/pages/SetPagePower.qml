import settings
import QtQuick
import QtQuick.Layouts

// System > Power & battery
//
// Everything on this page is read from the machine, never assumed:
//  - power profiles are discovered (dssos-settings-ctl power-list)
//  - the battery block disappears entirely when there is no battery
// On a VM you therefore see two profiles and no battery row; on the laptop you
// get three profiles and a live percentage.
ColumnLayout {
    Layout.fillWidth: true
    spacing: 0

    Text {
        text: "Power & battery"
        font.pixelSize: 24
        font.weight: Font.DemiBold
        color: SettingsTheme.text
        Layout.bottomMargin: 18
    }

    Text {
        // Hidden rather than faked when there is no battery to talk about.
        visible: SettingsState.batteryPresent
        text: "Battery status"
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: SettingsTheme.muted
        Layout.bottomMargin: 8
    }

    SetCard {
        visible: SettingsState.batteryPresent
        Layout.bottomMargin: 20

        SetRow {
            label: "Charge level: " + SettingsState.batteryLevel + "%"
            hint: {
                if (SettingsState.batteryStatus === "Charging")
                    return "Charging";
                if (SettingsState.batteryStatus === "Full")
                    return "Fully charged";
                return SettingsState.batteryStatus + " \\u00b7 estimated time remaining";
            }
            Rectangle {
                width: 120
                height: 10
                color: SettingsTheme.control
                border.width: 1
                border.color: SettingsTheme.edge
                Rectangle {
                    width: Math.round(parent.width * SettingsState.batteryLevel / 100)
                    height: parent.height
                    // Red only when it is actually low, so the bar carries meaning.
                    color: SettingsState.batteryLevel <= 15 ? "#e5484d" : SettingsTheme.accent
                    Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                }
            }
        }
    }

    Text {
        text: "Power mode"
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: SettingsTheme.muted
        Layout.bottomMargin: 8
    }

    SetCard {
        SetRow {
            label: "CPU power profile"
            hint: "Optimize CPU governor for battery life or responsiveness"
            stacked: true
            isLast: true

            SetRadio {
                options: {
                    if (SettingsState.powerProfiles.length === 0)
                        return ["Detecting profiles..."];
                    return SettingsState.powerProfiles.map(p => SettingsState.profileLabel(p));
                }
                current: SettingsState.powerProfileIndex
                onSelected: (idx) => SettingsState.setPowerProfileByIndex(idx)
            }

            Text {
                visible: SettingsState.powerProfiles.length === 0
                text: "No cpufreq driver on this machine"
                font.pixelSize: 12
                color: SettingsTheme.muted
            }
        }
    }

    Text {
        text: "Screen & sleep"
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: SettingsTheme.muted
        Layout.bottomMargin: 8
    }

    SetCard {
        SetRow {
            label: "Turn off screen on battery"
            SetDropdown {
                options: ["2 minutes", "5 minutes", "10 minutes", "Never"]
                current: 1
            }
        }

        SetRow {
            label: "Suspend when plugged in"
            SetDropdown {
                options: ["15 minutes", "30 minutes", "1 hour", "Never"]
                current: 2
            }
        }

        SetRow {
            label: "Laptop lid close action"
            isLast: true
            SetDropdown {
                options: ["Suspend", "Lock screen", "Do nothing"]
                current: 0
            }
        }
    }
}
