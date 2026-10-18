import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "."

Item {
    id: root
    property string text: ""
    property string iconName: ""
    property string variant: "card" // "card" | "accent" | "danger" | "dangerDark" | "ghost"
    property bool active: false

    signal clicked()

    implicitHeight: 30
    implicitWidth: contentRow.implicitWidth + 24

    readonly property color bgColor: {
        if (variant === "accent") {
            return mouseArea.pressed ? Qt.darker(Theme.accent, 1.2) : (mouseArea.containsMouse ? Qt.lighter(Theme.accent, 1.1) : Theme.accent);
        }
        if (variant === "danger") {
            return mouseArea.pressed ? Qt.darker(Theme.dangerBright, 1.2) : (mouseArea.containsMouse ? Qt.lighter(Theme.dangerBright, 1.1) : Theme.dangerBright);
        }
        if (variant === "dangerDark") {
            return mouseArea.pressed ? Qt.darker(Theme.dangerDark, 1.2) : (mouseArea.containsMouse ? "#361b1b" : Theme.dangerDark);
        }
        if (variant === "ghost") {
            return mouseArea.containsMouse ? Theme.cardHover : "transparent";
        }
        // Default "card"
        if (root.active) return Theme.selected;
        return mouseArea.pressed ? Theme.selected : (mouseArea.containsMouse ? Theme.cardHover : Theme.card);
    }

    readonly property color fgColor: {
        if (variant === "accent") return "#04130a";
        if (variant === "danger") return Theme.dangerText;
        if (variant === "dangerDark") return Theme.dangerRed;
        return Theme.text;
    }

    Rectangle {
        id: bgRect
        anchors.fill: parent
        color: root.bgColor

        RowLayout {
            id: contentRow
            anchors.centerIn: parent
            spacing: 6

            IconImage {
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
                source: root.iconName ? "image://icon/" + root.iconName : ""
                visible: root.iconName !== ""
            }

            Text {
                text: root.text
                color: root.fgColor
                font.pixelSize: Theme.fontSizeNormal
                font.weight: (root.variant === "accent" || root.variant === "danger") ? Font.DemiBold : Font.Normal
                font.family: Theme.fontFamily
                visible: root.text !== ""
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.clicked()
        }
    }
}
