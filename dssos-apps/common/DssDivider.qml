import QtQuick
import "."

Rectangle {
    id: root
    property string orientation: "horizontal" // "horizontal" | "vertical"
    color: Theme.divider

    width: orientation === "vertical" ? 1 : (parent ? parent.width : 100)
    height: orientation === "vertical" ? (parent ? parent.height : 100) : 1
}
