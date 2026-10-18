import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// The ONE context menu window for the whole OS. Single instance in shell.qml.
PanelWindow {
    id: ctx

    anchors {
        top: !ContextMenuState.openAbove
        bottom: ContextMenuState.openAbove
        left: true
    }
    margins {
        left: Math.max(8, Math.min(ContextMenuState.cursorX, (screen ? screen.width : 1366) - ctx.implicitWidth - 8))
        top: !ContextMenuState.openAbove ? ContextMenuState.topMargin : 0
        bottom: ContextMenuState.openAbove ? ContextMenuState.bottomMargin : 0
    }
    implicitWidth: 215
    implicitHeight: Math.min(360, list.implicitHeight + 14)
    onImplicitHeightChanged: if (shown) settleTimer.restart()
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    visible: true
    mask: (shown || closing) ? openMask : closedMask
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: (ctx.shown || ctx.closing) ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    property bool shown: false
    property bool closing: false

    NumberAnimation {
        id: fadeIn
        target: card
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
            card.opacity = 0.999;
            postSettleTimer.restart();
        }
    }

    Timer {
        id: postSettleTimer
        interval: 16
        repeat: false
        onTriggered: {
            card.opacity = 1.0;
        }
    }

    NumberAnimation {
        id: fadeOut
        target: card
        property: "opacity"
        to: 0
        duration: 90
        easing.type: Easing.InCubic
        onFinished: ctx.closing = false
    }

    Connections {
        target: ContextMenuState
        function onOpenChanged() {
            if (ContextMenuState.open) {
                fadeOut.stop();
                ctx.closing = false;
                ctx.shown = true;
                card.opacity = 0;
                fadeIn.restart();
                card.forceActiveFocus();
            } else if (ctx.shown) {
                fadeIn.stop();
                settleTimer.stop();
                postSettleTimer.stop();
                ctx.shown = false;
                ctx.closing = true;
                fadeOut.restart();
            }
        }
    }

    OutsideClick {
        targetLayer: WlrLayer.Top
        visible: ctx.shown || ctx.closing
        onClicked: ContextMenuState.hide()
        onRightClicked: (rx, ry) => {
            ContextMenuState.hide();
            if (ContextMenuState.desktopMenuCallback) {
                ContextMenuState.desktopMenuCallback(rx, ry);
            }
        }
    }

    Region { id: openMask; item: card }
    Region { id: closedMask; width: 0; height: 0 }

    Item {
        id: card
        anchors.fill: parent
        opacity: 0
        visible: ctx.shown || ctx.closing
        enabled: ctx.shown && !ctx.closing
        focus: true
        Keys.onEscapePressed: ContextMenuState.hide()

        Rectangle {
            anchors.fill: parent
            radius: 0
            color: Style.surface || "#000000"
            border.width: 1
            border.color: "#383838"
        }

        Flickable {
            anchors { fill: parent; topMargin: 6; bottomMargin: 6; leftMargin: 0; rightMargin: 0 }
            contentHeight: list.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: list
                width: parent.width
                spacing: 1

                Repeater {
                    model: ContextMenuState.rowsModel
                    delegate: Item {
                        required property int index
                        required property string label
                        required property string hint
                        required property bool danger
                        required property bool ison
                        required property string kind
                        width: list.width
                        height: kind === "sep" ? 9 : 32

                        // separator line
                        Rectangle {
                            visible: kind === "sep"
                            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 12; rightMargin: 12 }
                            height: 1
                            color: Style.text
                            opacity: 0.12
                        }

                        // action row
                        Rectangle {
                            visible: kind !== "sep"
                            anchors.fill: parent
                            radius: 0
                            color: Qt.rgba(1, 1, 1, !ison ? 0 : (rowMouse.pressed ? Style.press : (rowMouse.containsMouse ? Style.hover : 0)))

                            RowLayout {
                                anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
                                spacing: 10

                                Text {
                                    Layout.fillWidth: true
                                    text: label
                                    color: ison ? Style.text : Style.dim
                                    font.pixelSize: 13
                                    renderType: Text.NativeRendering
                                    elide: Text.ElideRight
                                }

                                Text {
                                    visible: hint !== ""
                                    text: hint
                                    // Style.disabled does not exist: the property list in Style.qml has no
                                    // `disabled`, so this evaluated to undefined and Qt
                                    // substituted transparent -- shortcuts on a greyed-out
                                    // row were invisible instead of dimmed.
                                    color: ison ? Style.dim : Style.border
                                    font.pixelSize: 11
                                    renderType: Text.NativeRendering
                                }
                            }

                            MouseArea {
                                id: rowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: ison
                                cursorShape: Qt.PointingHandCursor
                                onClicked: ContextMenuState.fire(index)
                            }
                        }
                    }
                }
            }
        }
    }
}
