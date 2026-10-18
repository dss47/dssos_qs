import QtQuick
import QtQuick.Layouts
import tasks
import common

Item {
    id: root

    property string deviceName: "dss-pc"
    property string processor: "Intel Core i7-7600U @ 2.80GHz"
    property string installedRam: "7.6 GB"
    property string graphics: "Intel HD Graphics 620"
    property string storage: "238 GB NVMe SSD"
    property string displayInfo: "1920 × 1080, 60 Hz"
    property string systemType: "64-bit operating system, x86_64"
    property string kernel: "Linux"
    property string installedOn: "16.10.2026"

    signal copySpecs()

    Flickable {
        id: flickable
        anchors.fill: parent
        contentWidth: width
        contentHeight: contentCol.height + 48
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: contentCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: 26
            anchors.rightMargin: 26
            anchors.topMargin: 22
            spacing: 20

            // 1. Section Device specifications
            Column {
                width: parent.width
                spacing: 8

                Text {
                    text: "Device specifications"
                    color: Theme.muted
                    font.pixelSize: Theme.fontSizeNormal
                    font.weight: Font.DemiBold
                    font.family: Theme.fontFamily
                }

                Rectangle {
                    width: parent.width
                    height: deviceSpecsCol.height
                    color: Theme.card

                    Column {
                        id: deviceSpecsCol
                        width: parent.width

                        DssRow { label: "Device name"; value: root.deviceName }
                        DssRow { label: "Processor"; value: root.processor }
                        DssRow { label: "Installed RAM"; value: root.installedRam }
                        DssRow { label: "Graphics"; value: root.graphics }
                        DssRow { label: "Storage"; value: root.storage }
                        DssRow { label: "Display"; value: root.displayInfo }
                        DssRow { label: "System type"; value: root.systemType }
                        DssRow { label: "Kernel"; value: root.kernel; showDivider: false }
                    }
                }
            }

            // 2. Section DssOS specifications
            Column {
                width: parent.width
                spacing: 8

                Text {
                    text: "DssOS specifications"
                    color: Theme.muted
                    font.pixelSize: Theme.fontSizeNormal
                    font.weight: Font.DemiBold
                    font.family: Theme.fontFamily
                }

                Rectangle {
                    width: parent.width
                    height: dssSpecsCol.height
                    color: Theme.card

                    Column {
                        id: dssSpecsCol
                        width: parent.width

                        DssRow { label: "Edition"; value: "DssOS" }
                        DssRow { label: "Version"; value: "1.0" }
                        DssRow { label: "Compositor"; value: "Wayfire" }
                        DssRow { label: "Shell"; value: "Quickshell" }
                        DssRow { label: "Installed on"; value: root.installedOn; showDivider: false }
                    }
                }
            }

            // 3. Action buttons
            Row {
                spacing: 8

                DssButton {
                    text: "Copy specs"
                    variant: "card"
                    onClicked: root.copySpecs()
                }
            }
        }
    }

    // Shared universal scrollbar
    DssScrollBar {
        target: flickable
    }
}
