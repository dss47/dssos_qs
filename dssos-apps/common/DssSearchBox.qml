import QtQuick
import QtQuick.Layouts
import "."

Rectangle {
    id: root
    height: 30
    color: Theme.control

    property alias text: searchInput.text
    property string placeholder: "Search"
    signal searchChanged(string query)
    signal accepted()

    function focusInput() {
        searchInput.forceActiveFocus();
    }

    function clear() {
        searchInput.text = "";
    }

    // 2px bottom border (accent color when focused)
    Rectangle {
        height: 2
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        color: searchInput.activeFocus ? Theme.accent : Theme.divider
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 6

        // Magnifying glass vector icon
        Canvas {
            id: searchIcon
            Layout.preferredWidth: 16
            Layout.preferredHeight: 16
            renderTarget: Canvas.FramebufferObject

            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                ctx.strokeStyle = Theme.muted;
                ctx.lineWidth = 1.6;
                ctx.lineCap = "round";

                ctx.beginPath();
                ctx.arc(6.5, 6.5, 4.5, 0, 2 * Math.PI);
                ctx.stroke();

                ctx.beginPath();
                ctx.moveTo(10, 10);
                ctx.lineTo(14, 14);
                ctx.stroke();
            }
        }

        TextInput {
            id: searchInput
            Layout.fillWidth: true
            color: Theme.text
            font.pixelSize: Theme.fontSizeNormal
            font.family: Theme.fontFamily
            clip: true
            selectByMouse: true

            Text {
                anchors.fill: parent
                text: root.placeholder
                color: Theme.muted
                font.pixelSize: Theme.fontSizeNormal
                font.family: Theme.fontFamily
                visible: !searchInput.text && !searchInput.activeFocus
            }

            onTextChanged: {
                root.searchChanged(text);
            }
            onAccepted: {
                root.accepted();
            }
        }

        // Clear button (visible when there is text)
        Text {
            Layout.preferredWidth: 16
            Layout.preferredHeight: 16
            text: "×"
            color: clearMouse.containsMouse ? Theme.text : Theme.muted
            font.pixelSize: 16
            font.family: Theme.fontFamily
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            visible: searchInput.text.length > 0

            MouseArea {
                id: clearMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.clear()
            }
        }
    }
}
