import settings
import QtQuick
import QtQuick.Layouts

// System > Display (Hardware-synchronized, dynamic modes)
ColumnLayout {
    Layout.fillWidth: true
    spacing: 0

    Text {
        text: "Display"
        font.pixelSize: 24
        font.weight: Font.DemiBold
        color: SettingsTheme.text
        Layout.bottomMargin: 18
    }

    Text {
        text: "Brightness"
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: SettingsTheme.muted
        Layout.bottomMargin: 8
    }

    SetCard {
        Layout.bottomMargin: 20

        SetRow {
            label: "Brightness"
            hint: SettingsState.hasBacklight ? "Adjust built-in panel backlight level" : "Brightness control not available (VM or external monitor)"
            isLast: true
            SetSlider {
                id: brightSlider
                enabled: SettingsState.hasBacklight
                from: 1
                to: 100
                value: SettingsState.brightness
                onMoved: (val) => SettingsState.setBrightness(Math.round(val))
            }
            Text {
                text: Math.round(brightSlider.value) + "%"
                font.pixelSize: 13
                color: brightSlider.enabled ? SettingsTheme.text : SettingsTheme.muted
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 38
            }
        }
    }

    Text {
        text: "Scale & layout"
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: SettingsTheme.muted
        Layout.bottomMargin: 8
    }

    SetCard {
        SetRow {
            label: "Scale"
            hint: "Change the size of text, apps, and UI elements"
            stacked: true
            Flow {
                Layout.fillWidth: true
                spacing: 10

                SetRadio {
                    options: SettingsState.availableScales
                    current: SettingsState.currentScaleIndex
                    onSelected: (idx) => SettingsState.applyScaleByIndex(idx)
                }

                RowLayout {
                    visible: SettingsState.currentScaleIndex === 3
                    spacing: 6

                    Rectangle {
                        width: 60
                        height: 32
                        color: SettingsTheme.control
                        border.width: 1
                        border.color: scaleInput.activeFocus ? SettingsTheme.accent : SettingsTheme.edge

                        TextInput {
                            id: scaleInput
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            verticalAlignment: TextInput.AlignVCenter
                            color: SettingsTheme.text
                            font.pixelSize: 13
                            text: SettingsState.displayScale
                            selectByMouse: true
                            onAccepted: {
                                let val = parseFloat(text);
                                if (!isNaN(val) && val >= 1.0 && val <= 3.0) {
                                    SettingsState.setCustomScale(val);
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: 55
                        height: 32
                        color: applyBtn.containsMouse ? SettingsTheme.hover : SettingsTheme.control
                        border.width: 1
                        border.color: SettingsTheme.edge

                        Text {
                            anchors.centerIn: parent
                            text: "Apply"
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: SettingsTheme.text
                        }

                        MouseArea {
                            id: applyBtn
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                let val = parseFloat(scaleInput.text);
                                // 1.0 floor is not cosmetic: wlroots casts scale to
                                // int32_t, so <1.0 becomes 0 and aborts wayfire.
                                if (!isNaN(val) && val >= 1.0 && val <= 3.0) {
                                    SettingsState.setCustomScale(val);
                                }
                            }
                        }
                    }
                }
            }
        }

        SetRow {
            label: "Resolution"
            hint: "Select the screen resolution"
            stacked: true
            SetRadio {
                options: SettingsState.availableResolutions.length > 0 ? SettingsState.availableResolutions : ["Detecting..."]
                current: SettingsState.currentResolutionIndex
                onSelected: (idx) => {
                    SettingsState.currentResolutionIndex = idx;
                    if (SettingsState.availableResolutions[idx]) {
                        SettingsState.setResolution(SettingsState.availableResolutions[idx], idx);
                    }
                }
            }
        }

        SetRow {
            label: "Refresh rate"
            hint: "Lower refresh rates conserve battery on laptops"
            isLast: true
            SetDropdown {
                options: SettingsState.availableRefreshRates.length > 0 ? SettingsState.availableRefreshRates : ["60 Hz"]
                current: SettingsState.currentRefreshIndex
                onActivated: (idx) => {
                    if (SettingsState.availableRefreshRates[idx]) {
                        SettingsState.setRefresh(SettingsState.availableRefreshRates[idx]);
                    }
                }
            }
        }
    }
}
