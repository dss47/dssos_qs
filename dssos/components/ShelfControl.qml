import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import Quickshell.Networking

Item {
    id: root

    implicitHeight: 250
    clip: true

    readonly property color cCard: "#131313"
    readonly property color cBorder: "#1c1c1c"
    readonly property color cText: "#f0f0f0"
    readonly property color cMuted: "#8c8c8c"
    readonly property color cGreen: "#34c77b"
    readonly property color cCtl: "#0a0a0a"

    // Toggle states for design
    property bool wifiActive: true
    property bool btActive: false
    property bool nightActive: false

    // Slider percentages
    property real brightnessVal: 0.62
    property real volumeVal: 0.45

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ------------------------------------------------------------- Column 1: Big Clock & Date
        Rectangle {
            Layout.preferredWidth: 320
            Layout.fillHeight: true
            color: "transparent"

            Rectangle {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 1
                color: root.cBorder
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 22
                anchors.leftMargin: 24
                anchors.rightMargin: 24
                spacing: 6

                Item { Layout.fillHeight: true }

                Text {
                    text: Qt.formatTime(clock.date, "hh:mm")
                    color: root.cText
                    font.pixelSize: 44
                    font.weight: Font.Normal
                    lineHeight: 1.0
                }

                Text {
                    text: Qt.formatDate(clock.date, "dddd, d MMMM yyyy")
                    color: root.cMuted
                    font.pixelSize: 13
                }

                Item { Layout.fillHeight: true }
            }
        }

        // ------------------------------------------------------------- Column 2: Toggles (Wi-Fi, Bluetooth, Night light)
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "transparent"

            Rectangle {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 1
                color: root.cBorder
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 22
                anchors.leftMargin: 24
                anchors.rightMargin: 24
                spacing: 8

                // Row 1: Wi-Fi
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    color: "transparent"

                    RowLayout {
                        anchors.fill: parent
                        spacing: 14

                        Item {
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24
                            Layout.alignment: Qt.AlignVCenter

                            Image {
                                anchors.centerIn: parent
                                width: 18; height: 18
                                sourceSize: Qt.size(36, 36)
                                source: "../assets/icons/wifi.svg"
                                opacity: 0.7
                            }
                        }

                        ColumnLayout {
                            spacing: 2
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter

                            Text {
                                text: "Wi-Fi"
                                color: root.cText
                                font.pixelSize: 13
                                font.weight: Font.Normal
                            }

                            Text {
                                text: root.wifiActive ? "HUAWEI_6G" : "Disconnected"
                                color: root.cMuted
                                font.pixelSize: 11
                            }
                        }

                        // Toggle switch
                        Rectangle {
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 20
                            Layout.alignment: Qt.AlignVCenter
                            color: root.wifiActive ? root.cGreen : root.cCtl
                            border.width: 1
                            border.color: root.wifiActive ? root.cGreen : root.cMuted

                            Rectangle {
                                width: 12
                                height: 12
                                anchors.verticalCenter: parent.verticalCenter
                                x: root.wifiActive ? (parent.width - width - 4) : 4
                                color: root.wifiActive ? "#04130a" : root.cMuted
                                Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.wifiActive = !root.wifiActive
                            }
                        }
                    }
                }

                // Row 2: Bluetooth
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    color: "transparent"

                    RowLayout {
                        anchors.fill: parent
                        spacing: 14

                        Item {
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24
                            Layout.alignment: Qt.AlignVCenter

                            Image {
                                anchors.centerIn: parent
                                width: 18; height: 18
                                sourceSize: Qt.size(36, 36)
                                source: "../assets/icons/bluetooth.svg"
                                opacity: 0.7
                            }
                        }

                        ColumnLayout {
                            spacing: 2
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter

                            Text {
                                text: "Bluetooth"
                                color: root.cText
                                font.pixelSize: 13
                                font.weight: Font.Normal
                            }

                            Text {
                                text: root.btActive ? "Connected" : "Off"
                                color: root.cMuted
                                font.pixelSize: 11
                            }
                        }

                        // Toggle switch
                        Rectangle {
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 20
                            Layout.alignment: Qt.AlignVCenter
                            color: root.btActive ? root.cGreen : root.cCtl
                            border.width: 1
                            border.color: root.btActive ? root.cGreen : root.cMuted

                            Rectangle {
                                width: 12
                                height: 12
                                anchors.verticalCenter: parent.verticalCenter
                                x: root.btActive ? (parent.width - width - 4) : 4
                                color: root.btActive ? "#04130a" : root.cMuted
                                Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.btActive = !root.btActive
                            }
                        }
                    }
                }

                // Row 3: Night light
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    color: "transparent"

                    RowLayout {
                        anchors.fill: parent
                        spacing: 14

                        Item {
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24
                            Layout.alignment: Qt.AlignVCenter

                            Image {
                                anchors.centerIn: parent
                                width: 18; height: 18
                                sourceSize: Qt.size(36, 36)
                                source: "../assets/icons/moon.svg"
                                opacity: 0.7
                            }
                        }

                        ColumnLayout {
                            spacing: 2
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter

                            Text {
                                text: "Night light"
                                color: root.cText
                                font.pixelSize: 13
                                font.weight: Font.Normal
                            }

                            Text {
                                text: root.nightActive ? "On" : "After sunset"
                                color: root.cMuted
                                font.pixelSize: 11
                            }
                        }

                        // Toggle switch
                        Rectangle {
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 20
                            Layout.alignment: Qt.AlignVCenter
                            color: root.nightActive ? root.cGreen : root.cCtl
                            border.width: 1
                            border.color: root.nightActive ? root.cGreen : root.cMuted

                            Rectangle {
                                width: 12
                                height: 12
                                anchors.verticalCenter: parent.verticalCenter
                                x: root.nightActive ? (parent.width - width - 4) : 4
                                color: root.nightActive ? "#04130a" : root.cMuted
                                Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.nightActive = !root.nightActive
                            }
                        }
                    }
                }
            }
        }

        // ------------------------------------------------------------- Column 3: Sliders & Battery
        Rectangle {
            Layout.preferredWidth: 300
            Layout.fillHeight: true
            color: "transparent"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 22
                anchors.leftMargin: 24
                anchors.rightMargin: 24
                spacing: 8

                // Slider 1: Brightness
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    color: "transparent"

                    RowLayout {
                        anchors.fill: parent
                        spacing: 14

                        Item {
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24
                            Layout.alignment: Qt.AlignVCenter

                            Image {
                                anchors.centerIn: parent
                                width: 18; height: 18
                                sourceSize: Qt.size(36, 36)
                                source: "../assets/icons/sun-medium.svg"
                                opacity: 0.7
                            }
                        }

                        Item {
                            id: bTrack
                            Layout.fillWidth: true
                            Layout.preferredHeight: 4
                            Layout.alignment: Qt.AlignVCenter

                            Rectangle {
                                anchors.fill: parent
                                color: root.cCard
                            }

                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: parent.width * root.brightnessVal
                                color: root.cGreen
                            }

                            Rectangle {
                                width: 10
                                height: 16
                                anchors.verticalCenter: parent.verticalCenter
                                x: (bTrack.width * root.brightnessVal) - 5
                                color: root.cGreen
                            }

                            MouseArea {
                                anchors.fill: parent
                                anchors.topMargin: -10
                                anchors.bottomMargin: -10
                                cursorShape: Qt.PointingHandCursor
                                onPressed: (mouse) => {
                                    root.brightnessVal = Math.max(0, Math.min(1, mouse.x / bTrack.width));
                                }
                                onPositionChanged: (mouse) => {
                                    if (pressed) {
                                        root.brightnessVal = Math.max(0, Math.min(1, mouse.x / bTrack.width));
                                    }
                                }
                            }
                        }

                        Text {
                            text: Math.round(root.brightnessVal * 100) + "%"
                            color: root.cMuted
                            font.pixelSize: 13
                            Layout.preferredWidth: 40
                            Layout.alignment: Qt.AlignVCenter
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }

                // Slider 2: Volume
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    color: "transparent"

                    RowLayout {
                        anchors.fill: parent
                        spacing: 14

                        Item {
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24
                            Layout.alignment: Qt.AlignVCenter

                            Image {
                                anchors.centerIn: parent
                                width: 18; height: 18
                                sourceSize: Qt.size(36, 36)
                                source: "../assets/icons/volume-2.svg"
                                opacity: 0.7
                            }
                        }

                        Item {
                            id: vTrack
                            Layout.fillWidth: true
                            Layout.preferredHeight: 4
                            Layout.alignment: Qt.AlignVCenter

                            Rectangle {
                                anchors.fill: parent
                                color: root.cCard
                            }

                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: parent.width * root.volumeVal
                                color: root.cGreen
                            }

                            Rectangle {
                                width: 10
                                height: 16
                                anchors.verticalCenter: parent.verticalCenter
                                x: (vTrack.width * root.volumeVal) - 5
                                color: root.cGreen
                            }

                            MouseArea {
                                anchors.fill: parent
                                anchors.topMargin: -10
                                anchors.bottomMargin: -10
                                cursorShape: Qt.PointingHandCursor
                                onPressed: (mouse) => {
                                    root.volumeVal = Math.max(0, Math.min(1, mouse.x / vTrack.width));
                                }
                                onPositionChanged: (mouse) => {
                                    if (pressed) {
                                        root.volumeVal = Math.max(0, Math.min(1, mouse.x / vTrack.width));
                                    }
                                }
                            }
                        }

                        Text {
                            text: Math.round(root.volumeVal * 100) + "%"
                            color: root.cMuted
                            font.pixelSize: 13
                            Layout.preferredWidth: 40
                            Layout.alignment: Qt.AlignVCenter
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }

                // Battery Row
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    color: "transparent"

                    RowLayout {
                        anchors.fill: parent
                        spacing: 14

                        Item {
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24
                            Layout.alignment: Qt.AlignVCenter

                            Image {
                                anchors.centerIn: parent
                                width: 18; height: 18
                                sourceSize: Qt.size(36, 36)
                                source: "../assets/icons/battery-medium.svg"
                                opacity: 0.7
                            }
                        }

                        RowLayout {
                            spacing: 8
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter

                            Text {
                                text: "84%"
                                color: root.cText
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: "3 h 40 min left"
                                color: root.cMuted
                                font.pixelSize: 13
                            }
                        }
                    }
                }
            }
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
