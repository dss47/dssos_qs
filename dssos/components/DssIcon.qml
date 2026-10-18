import QtQuick

Item {
    id: root

    property string name: ""
    property color color: "#8c8c8c"
    property real iconSize: 18
    property real strokeWidth: 1.6

    implicitWidth: iconSize
    implicitHeight: iconSize

    Image {
        anchors.fill: parent
        sourceSize.width: root.iconSize * 2
        sourceSize.height: root.iconSize * 2
        source: root.name !== "" ? DssIcons.get(root.name, root.color, root.strokeWidth) : ""
        fillMode: Image.PreserveAspectFit
        smooth: true
        asynchronous: true
        cache: true
    }
}
