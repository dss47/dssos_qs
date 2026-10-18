import QtQuick
import tasks
import common

DssStatusBar {
    id: root
    property int processCount: 0
    property string uptimeText: "Uptime 0:00:00"

    leftText: root.processCount + " processes"
    middleText: root.uptimeText
    rightText: "Space: select · Del: end task"
}
