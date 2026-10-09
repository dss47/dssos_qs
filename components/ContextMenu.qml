import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

// The ONE context menu window for the whole OS. Single instance in shell.qml.
// Opens upward from (ax, marginBottom). View binds to primitive lists only.
PanelWindow {
    id: ctx

    anchors { bottom: true; left: true }
    margins {
        // fixed 220px width, so clamping is exact; opens above marginBottom
        left: Math.max(8, Math.min(ContextMenuState.ax - 8, screen.width - 220 - 8))
        bottom: ContextMenuState.marginBottom
    }
    implicitWidth: 220
    implicitHeight: Math.min(360, list.implicitHeight + 16)
    color: "transparent"
    visible: true
    mask: ctx.shown ? openMask : closedMask
    exclusionMode: ExclusionMode.Ignore

    property bool shown: false
    // true while fading out: card visible but dead (no mask, no clicks)
    property bool closing: false

    HyprlandFocusGrab {
        windows: [ctx]
        active: ctx.shown && ContextMenuState.open
        onCleared: ContextMenuState.hide()
    }

    Region { id: openMask; item: card }
    Region { id: closedMask; width: 0; height: 0 }

    // fast fade, no slide: menus must feel instant
    NumberAnimation {
        id: fadeIn
        target: card
        property: "opacity"
        to: 1
        duration: 120
        easing.type: Easing.OutCubic
    }
    NumberAnimation {
        id: fadeOut
        target: card
        property: "opacity"
        to: 0
        duration: 100
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
            } else if (ctx.shown) {
                fadeIn.stop();
                ctx.shown = false;   // drop the input mask NOW, card keeps fading
                ctx.closing = true;
                fadeOut.restart();
            }
        }
    }

    Item {
        id: card
        width: parent.width
        height: parent.height
        opacity: 0
        visible: ctx.shown || ctx.closing
        enabled: ctx.shown && !ctx.closing
        focus: true
        Keys.onEscapePressed: ContextMenuState.hide()

        Rectangle {
            anchors.fill: parent
            radius: 14
            color: Style.surface
            border.width: 1
            border.color: Style.border
        }

        Flickable {
            anchors { fill: parent; margins: 8 }
            contentHeight: list.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            Column {
                id: list
                width: parent.width
                spacing: 2
                // app name header
                Text {
                    visible: ContextMenuState.title !== ""
                    width: parent.width
                    height: 28
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: 12
                    text: ContextMenuState.title
                    color: Style.dim
                    font.pixelSize: 12
                    font.bold: true
                    elide: Text.ElideRight
                }
                Repeater {
                    model: ContextMenuState.rowsModel
                    delegate: Item {
                        required property int index
                        required property string label
                        required property string icon
                        required property string hint
                        required property bool danger
                        required property bool ison
                        required property string kind
                        width: list.width
                        height: kind === "sep" ? 9 : 36

                        // separator line
                        Rectangle {
                            visible: kind === "sep"
                            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 12; rightMargin: 12 }
                            height: 1
                            color: Style.text
                            opacity: 0.1
                        }

                        // action row (highlight animates color alpha, NOT opacity:
                        // opacity would fade the labels nested inside too)
                        Rectangle {
                            visible: kind !== "sep"
                            anchors.fill: parent
                            radius: 8
                            color: Qt.rgba(1, 1, 1, !ison ? 0 : (rowMouse.pressed ? Style.press : (rowMouse.containsMouse ? Style.hover : 0)))
                            Behavior on color { ColorAnimation { duration: 80 } }

                            RowLayout {
                                anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                                spacing: 10
                                Image {
                                    visible: icon !== ""
                                    Layout.preferredWidth: 15
                                    Layout.preferredHeight: 15
                                    sourceSize.width: 30
                                    sourceSize.height: 30
                                    source: icon !== "" ? "../assets/icons/" + icon + ".svg" : ""
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: label
                                    color: danger ? Style.danger : (ison ? Style.text : Style.dim)
                                    font.pixelSize: 13
                                    elide: Text.ElideRight
                                }
                                // shortcut hint pill, like ⌘C
                                Rectangle {
                                    visible: hint !== ""
                                    Layout.preferredWidth: hintText.implicitWidth + 12
                                    Layout.preferredHeight: 20
                                    radius: 6
                                    color: "transparent"
                                    border.width: 1
                                    border.color: Style.text
                                    opacity: 0.35
                                    Text {
                                        id: hintText
                                        anchors.centerIn: parent
                                        text: hint
                                        color: Style.text
                                        font.pixelSize: 11
                                    }
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
