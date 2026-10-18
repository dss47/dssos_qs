import QtQuick
import QtQuick.Layouts
import tasks
import common

Item {
    id: root
    width: parent ? parent.width : 500
    height: isSelected ? 44 + detailBlock.height : 44

    property int pid: 0
    property string name: ""
    property bool isApp: false
    property color iconColor: "#4da3ff"
    property real cpuVal: 0.0
    property real memVal: 0.0    // in MB
    property real diskVal: 0.0   // in MB/s
    property real netVal: 0.0    // in Mbps
    property int threads: 1
    property string exePath: ""

    property int activeSort: 0   // 0: CPU, 1: Mem, 2: Disk, 3: Net
    property bool isSelected: false

    signal rowClicked()
    signal endTask(int targetPid)
    signal forceQuit(int targetPid)
    signal openLocation(string path, int targetPid)
    signal contextMenuRequested(real gx, real gy)

    // Formatter functions
    function formattedCurrentVal(): string {
        if (activeSort === 0) return cpuVal.toFixed(1) + "%";
        if (activeSort === 1) {
            return memVal >= 1024 ? (memVal / 1024.0).toFixed(1) + " GB" : Math.round(memVal) + " MB";
        }
        if (activeSort === 2) return diskVal.toFixed(1) + " MB/s";
        return netVal.toFixed(1) + " Mbps";
    }

    function currentRatio(): real {
        var v = 0;
        var max = 1.0;
        if (activeSort === 0) { v = cpuVal; max = 100.0; }
        else if (activeSort === 1) { v = memVal; max = 4096.0; }
        else if (activeSort === 2) { v = diskVal; max = 50.0; }
        else { v = netVal; max = 20.0; }
        return Math.max(0.02, Math.min(1.0, v / max));
    }

    function currentColor(): color {
        if (activeSort === 0) return Theme.cpu;
        if (activeSort === 1) return Theme.memory;
        if (activeSort === 2) return Theme.disk;
        return Theme.network;
    }

    Rectangle {
        id: bgRect
        anchors.fill: parent
        color: root.isSelected ? Theme.selected : (mouseArea.containsMouse ? Theme.rowHover : "transparent")

        // 3px green accent bar on left when selected
        Rectangle {
            width: 3
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            color: Theme.accent
            visible: root.isSelected
        }

        // Header Row (44px)
        Item {
            id: headerRow
            width: parent.width
            height: 44
            anchors.top: parent.top

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 12

                // 24x24 colored icon with first letter
                Rectangle {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    color: root.iconColor

                    Text {
                        anchors.centerIn: parent
                        text: root.name.length > 0 ? root.name.charAt(0).toUpperCase() : "?"
                        color: "#050505"
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        font.family: Theme.fontFamily
                    }
                }

                // Name and subtitle (Flex)
                Column {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        width: parent.width
                        text: root.name
                        color: Theme.text
                        font.pixelSize: Theme.fontSizeNormal
                        font.family: Theme.fontFamily
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        wrapMode: Text.NoWrap
                        clip: true
                    }

                    Text {
                        text: (root.isApp ? "App" : "Background") + " · PID " + root.pid
                        color: Theme.muted
                        font.pixelSize: Theme.fontSizeSmall
                        font.family: Theme.fontFamily
                    }
                }

                // Value block (150px, right aligned)
                Column {
                    Layout.preferredWidth: 150
                    spacing: 4

                    Text {
                        anchors.right: parent.right
                        text: root.formattedCurrentVal()
                        color: Theme.text
                        font.pixelSize: Theme.fontSizeNormal
                        font.weight: Font.Medium
                        font.family: Theme.fontFamily
                    }

                    // 3px gauge bar
                    DssMetricBar {
                        width: parent.width
                        ratio: root.currentRatio()
                        barColor: root.currentColor()
                    }
                }
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onPressed: (mouse) => {
                    if (mouse.button === Qt.RightButton) {
                        root.rowClicked();
                        var pt = mapToItem(null, mouse.x, mouse.y);
                        root.contextMenuRequested(pt.x, pt.y);
                    }
                }
                onClicked: (mouse) => {
                    if (mouse.button === Qt.LeftButton) {
                        root.rowClicked();
                    }
                }
            }
        }

        // Expanded detail section
        Item {
            id: detailBlock
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: headerRow.bottom
            height: root.isSelected ? 80 : 0
            visible: root.isSelected
            clip: true

            Column {
                anchors.fill: parent
                anchors.leftMargin: 48
                anchors.rightMargin: 12
                anchors.topMargin: 2
                anchors.bottomMargin: 12
                spacing: 10

                // 4 metrics columns
                RowLayout {
                    width: parent.width
                    spacing: 16

                    Column {
                        Layout.fillWidth: true
                        Text { text: "CPU"; color: Theme.muted; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily }
                        Text { text: root.cpuVal.toFixed(1) + "%"; color: Theme.text; font.pixelSize: Theme.fontSizeNormal; font.family: Theme.fontFamily }
                    }

                    Column {
                        Layout.fillWidth: true
                        Text { text: "Memory"; color: Theme.muted; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily }
                        Text {
                            text: root.memVal >= 1024 ? (root.memVal / 1024.0).toFixed(1) + " GB" : Math.round(root.memVal) + " MB"
                            color: Theme.text
                            font.pixelSize: Theme.fontSizeNormal
                            font.family: Theme.fontFamily
                        }
                    }

                    Column {
                        Layout.fillWidth: true
                        Text { text: "Disk"; color: Theme.muted; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily }
                        Text { text: root.diskVal.toFixed(1) + " MB/s"; color: Theme.text; font.pixelSize: Theme.fontSizeNormal; font.family: Theme.fontFamily }
                    }

                    Column {
                        Layout.fillWidth: true
                        Text { text: "Threads"; color: Theme.muted; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily }
                        Text { text: "" + root.threads; color: Theme.text; font.pixelSize: Theme.fontSizeNormal; font.family: Theme.fontFamily }
                    }
                }

                // Action buttons
                Row {
                    spacing: 6

                    DssButton {
                        height: 28
                        text: "End task"
                        variant: "dangerDark"
                        onClicked: root.endTask(root.pid)
                    }

                    DssButton {
                        height: 28
                        text: "Force quit"
                        variant: "danger"
                        onClicked: root.forceQuit(root.pid)
                    }

                    DssButton {
                        height: 28
                        text: "Open location"
                        variant: "card"
                        onClicked: root.openLocation(root.exePath, root.pid)
                    }
                }
            }
        }
    }
}
