import QtQuick
import tasks
import common

Rectangle {
    id: root
    width: Theme.sidebarWidth
    color: Theme.sidebar

    property int activeSort: 0
    property string currentView: "ov"

    property string cpuValue: "0%"
    property string cpuSubtitle: "Cores"
    property var cpuHistory: []

    property string memValue: "0 GB"
    property string memSubtitle: ""
    property var memHistory: []

    property string diskValue: "0 MB/s"
    property string diskSubtitle: ""
    property var diskHistory: []

    property string netValue: "0 Mbps"
    property string netSubtitle: ""
    property var netHistory: []

    signal selectSort(int index)

    // Right border 1px divider
    Rectangle {
        width: 1
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        color: Theme.dividerSide
        z: 10
    }

    Column {
        anchors.fill: parent

        ResourceTile {
            label: "CPU"
            value: root.cpuValue
            subtitle: root.cpuSubtitle
            resourceColor: Theme.cpu
            history: root.cpuHistory
            isSelected: root.currentView === "ps" && root.activeSort === 0
            onClicked: root.selectSort(0)
        }

        ResourceTile {
            label: "Memory"
            value: root.memValue
            subtitle: root.memSubtitle
            resourceColor: Theme.memory
            history: root.memHistory
            isSelected: root.currentView === "ps" && root.activeSort === 1
            onClicked: root.selectSort(1)
        }

        ResourceTile {
            label: "Disk"
            value: root.diskValue
            subtitle: root.diskSubtitle
            resourceColor: Theme.disk
            history: root.diskHistory
            isSelected: root.currentView === "ps" && root.activeSort === 2
            onClicked: root.selectSort(2)
        }

        ResourceTile {
            label: "Network"
            value: root.netValue
            subtitle: root.netSubtitle
            resourceColor: Theme.network
            history: root.netHistory
            isSelected: root.currentView === "ps" && root.activeSort === 3
            onClicked: root.selectSort(3)
        }
    }
}
