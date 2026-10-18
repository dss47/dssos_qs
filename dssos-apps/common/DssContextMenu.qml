import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: root

    property bool open: false
    property bool closing: false
    property var items: []
    property real targetX: 0
    property real targetY: 0
    property int menuWidth: 215

    anchors.fill: parent
    visible: open || closing
    z: 9999

    signal rightClickedOutside(real globalX, real globalY)

    NumberAnimation {
        id: fadeIn
        target: menuCard
        property: "opacity"
        to: 1
        duration: 120
        easing.type: Easing.OutCubic
        onFinished: settleTimer.restart()
    }

    Timer {
        id: settleTimer
        interval: 30
        repeat: false
        onTriggered: {
            menuCard.opacity = 0.999;
            postSettleTimer.restart();
        }
    }

    Timer {
        id: postSettleTimer
        interval: 16
        repeat: false
        onTriggered: {
            menuCard.opacity = 1.0;
        }
    }

    NumberAnimation {
        id: fadeOut
        target: menuCard
        property: "opacity"
        to: 0
        duration: 90
        easing.type: Easing.InCubic
        onFinished: {
            root.closing = false;
            root.items = [];
        }
    }

    function popup(x, y, menuItems) {
        if (!menuItems || menuItems.length === 0) return;
        fadeOut.stop();
        root.closing = false;
        root.items = menuItems;

        // Estimer la hauteur pour le clamping vertical
        var estHeight = 8;
        for (var i = 0; i < menuItems.length; i++) {
            estHeight += menuItems[i].separator ? 9 : 32;
        }

        // Clamp horizontal : s'ouvre vers la gauche si trop proche du bord droit
        var finalX = x;
        if (x + root.menuWidth > root.width - 8) {
            finalX = Math.max(8, x - root.menuWidth);
        }

        // Clamp vertical : ouvre en-dessous si curseur dans la moitié supérieure, au-dessus si dans la moitié inférieure
        var finalY = y;
        if (y > root.height / 2 || y + estHeight > root.height - 8) {
            finalY = Math.max(8, y - estHeight);
        }

        root.targetX = finalX;
        root.targetY = finalY;
        root.open = true;
        menuCard.opacity = 0;
        fadeIn.restart();
        menuCard.forceActiveFocus();

        // Dismiss desktop context menu so strictly one menu exists in the OS
        Quickshell.execDetached(["qs", "ipc", "-p", DssPaths.shellEntry, "call", "context", "hide"]);
    }

    function dismiss() {
        if (!root.open) return;
        fadeIn.stop();
        settleTimer.stop();
        postSettleTimer.stop();
        root.open = false;
        root.closing = true;
        fadeOut.restart();
    }

    function dismissImmediate() {
        fadeIn.stop();
        fadeOut.stop();
        settleTimer.stop();
        postSettleTimer.stop();
        root.open = false;
        root.closing = false;
        root.items = [];
        menuCard.opacity = 0;
    }

    // Zone d'interception modale (clic n'importe où en dehors ferme le menu)
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        hoverEnabled: false
        enabled: root.open
        onPressed: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                var pt = mapToItem(null, mouse.x, mouse.y);
                root.dismissImmediate();
                root.rightClickedOutside(pt.x, pt.y);
            } else {
                root.dismiss();
            }
        }
    }

    Rectangle {
        id: menuCard
        x: root.targetX
        y: root.targetY
        width: root.menuWidth
        implicitHeight: menuColumn.implicitHeight + 14
        opacity: 0
        color: "#000000"
        border.width: 1
        border.color: "#383838"
        radius: 0

        focus: true
        Keys.onEscapePressed: root.dismiss()

        Column {
            id: menuColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 6
            anchors.bottomMargin: 6
            spacing: 1

            Repeater {
                model: root.items

                Item {
                    id: rowItem
                    width: menuColumn.width
                    height: modelData.separator ? 9 : 32

                    // Separator 1px (identical to desktop ContextMenu)
                    Rectangle {
                        visible: !!modelData.separator
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        height: 1
                        color: "#ffffff"
                        opacity: 0.12
                    }

                    // Action row (identical hover brightness 0.15 and press 0.3 to desktop)
                    Rectangle {
                        id: btnRect
                        visible: !modelData.separator
                        anchors.fill: parent
                        radius: 0
                        readonly property bool isActionEnabled: modelData.enabled !== false
                        color: Qt.rgba(1, 1, 1, !isActionEnabled ? 0 : (rowMouse.pressed ? 0.3 : (rowMouse.containsMouse ? 0.15 : 0)))

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            spacing: 10

                            Text {
                                text: modelData.label || ""
                                color: btnRect.isActionEnabled ? "#ffffff" : "#9a9cb5"
                                font.pixelSize: 13
                                Layout.alignment: Qt.AlignVCenter
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                renderType: Text.NativeRendering
                            }

                            Text {
                                visible: !!modelData.shortcut
                                text: modelData.shortcut || ""
                                color: btnRect.isActionEnabled ? "#9a9cb5" : "#555555"
                                font.pixelSize: 11
                                Layout.alignment: Qt.AlignVCenter
                                renderType: Text.NativeRendering
                            }
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: btnRect.isActionEnabled
                            cursorShape: btnRect.isActionEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            acceptedButtons: Qt.LeftButton
                            onClicked: {
                                if (!btnRect.isActionEnabled) return;
                                var act = modelData.action;
                                root.dismissImmediate();
                                if (typeof act === "function") {
                                    act();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
