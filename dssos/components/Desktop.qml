import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Wayland

// Desktop background surface with icons, drag snap outlines, and context menu
PanelWindow {
    id: desktopWin

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    readonly property color cGreen: "#34c77b"
    readonly property color cBorder: "#1c1c1c"
    readonly property color cSel: "#14251a"

    // Grid configuration
    readonly property int cellW: 84
    readonly property int cellH: 96
    readonly property int gridMargin: 16

    // Selection & Drag state
    property var desktopItems: []
    property string selectedId: ""
    property bool isDragging: false
    property string draggingId: ""
    property int targetGridX: 0
    property int targetGridY: 0

    // Rubber-band multi-selection box
    property bool isSelecting: false
    property real selectStartX: 0
    property real selectStartY: 0
    property real selectCurX: 0
    property real selectCurY: 0

    // Load desktop items
    Process {
        id: loadItemsProc
        command: ["python3", ShellPaths.quickshellDir + "/dssos/scripts/get-desktop-items.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    if (Array.isArray(data)) {
                        desktopWin.desktopItems = data;
                    }
                } catch(e) {}
            }
        }
    }

    Component.onCompleted: {
        loadItemsProc.running = true;
        ContextMenuState.desktopMenuCallback = openMenu;
    }

    function refresh() {
        refreshAnim.restart();
        loadItemsProc.running = true;
    }

    function saveItemPos(itemId, gx, gy) {
        Quickshell.execDetached([
            "python3",
            ShellPaths.quickshellDir + "/dssos/scripts/get-desktop-items.py",
            "--save-pos",
            itemId,
            gx.toString(),
            gy.toString()
        ]);
    }

    // Refresh animation pulse
    Rectangle {
        id: refreshPulse
        anchors.fill: parent
        color: "#ffffff"
        opacity: 0
        visible: opacity > 0

        NumberAnimation on opacity {
            id: refreshAnim
            from: 0.12
            to: 0.0
            duration: 120
            running: false
        }
    }

    Shortcut {
        sequence: "F5"
        onActivated: desktopWin.refresh()
    }

    // ----------------------------------------------------------------- Drag Snapping Outline
    Rectangle {
        id: dragSnapOutline
        visible: desktopWin.isDragging
        x: desktopWin.gridMargin + desktopWin.targetGridX * desktopWin.cellW
        y: desktopWin.gridMargin + desktopWin.targetGridY * desktopWin.cellH
        width: desktopWin.cellW
        height: desktopWin.cellH
        color: desktopWin.cSel
        border.width: 1
        border.color: desktopWin.cGreen
        opacity: 0.75
        z: 5

        Behavior on x { NumberAnimation { duration: 60 } }
        Behavior on y { NumberAnimation { duration: 60 } }
    }

    // ----------------------------------------------------------------- Rubber-band Selection Box
    Rectangle {
        id: rubberBand
        visible: desktopWin.isSelecting
        x: Math.min(desktopWin.selectStartX, desktopWin.selectCurX)
        y: Math.min(desktopWin.selectStartY, desktopWin.selectCurY)
        width: Math.abs(desktopWin.selectCurX - desktopWin.selectStartX)
        height: Math.abs(desktopWin.selectCurY - desktopWin.selectStartY)
        color: desktopWin.cSel
        border.width: 1
        border.color: desktopWin.cGreen
        opacity: 0.45
        z: 6
    }

    // ----------------------------------------------------------------- Desktop Icons Canvas
    Item {
        id: iconsContainer
        anchors.fill: parent

        Repeater {
            model: desktopWin.desktopItems

            delegate: Item {
                id: itemDelegate
                required property var modelData

                property string itemId: modelData.id
                property string itemName: modelData.name
                property string itemIcon: modelData.icon
                property string itemExec: modelData.exec
                property int curGridX: modelData.gridX
                property int curGridY: modelData.gridY

                property bool isThisDragging: desktopWin.isDragging && desktopWin.draggingId === itemId
                property bool isSelected: desktopWin.selectedId === itemId

                width: desktopWin.cellW
                height: desktopWin.cellH

                x: isThisDragging ? dragPos.x : (desktopWin.gridMargin + curGridX * desktopWin.cellW)
                y: isThisDragging ? dragPos.y : (desktopWin.gridMargin + curGridY * desktopWin.cellH)
                z: isThisDragging ? 10 : 2

                property point dragPos: Qt.point(0, 0)
                property point grabOffset: Qt.point(0, 0)

                Rectangle {
                    anchors.centerIn: parent
                    width: desktopWin.cellW - 8
                    height: desktopWin.cellH - 8
                    color: isSelected ? desktopWin.cSel : (iconMouse.containsMouse ? "#121212" : "transparent")
                    border.width: 1
                    border.color: isSelected ? desktopWin.cGreen : (iconMouse.containsMouse ? "#2a2a2a" : "transparent")
                    opacity: isThisDragging ? 0.75 : 1.0

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 4

                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 44
                            Layout.alignment: Qt.AlignHCenter

                            IconImage {
                                anchors.centerIn: parent
                                implicitSize: 38
                                source: Quickshell.iconPath(itemDelegate.itemIcon, "application-x-executable")
                                asynchronous: true
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            Rectangle {
                                anchors.centerIn: nameLabel
                                width: nameLabel.implicitWidth + 6
                                height: nameLabel.implicitHeight + 2
                                color: "#000000"
                                opacity: isSelected ? 0.8 : 0.45
                            }

                            Text {
                                id: nameLabel
                                anchors.centerIn: parent
                                width: parent.width - 4
                                text: itemDelegate.itemName
                                color: "#ffffff"
                                font.pixelSize: 11
                                font.weight: isSelected ? Font.DemiBold : Font.Normal
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                maximumLineCount: 2
                                wrapMode: Text.WrapAnywhere
                            }
                        }
                    }
                }

                MouseArea {
                    id: iconMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onPressed: (mouse) => {
                        if (mouse.button === Qt.RightButton) {
                            desktopWin.selectedId = itemDelegate.itemId;
                            ContextMenuState.showAt(mouse.x + itemDelegate.x, mouse.y + itemDelegate.y, [
                                {
                                    label: "Open " + itemDelegate.itemName,
                                    action: function() { Quickshell.execDetached(["sh", "-c", itemDelegate.itemExec]); }
                                },
                                { sep: true },
                                {
                                    label: "Terminal here",
                                    action: function() { Quickshell.execDetached(["foot"]); }
                                },
                                {
                                    label: "Refresh Desktop",
                                    action: function() { desktopWin.refresh(); }
                                }
                            ], desktopWin.height);
                            return;
                        }

                        desktopWin.selectedId = itemDelegate.itemId;
                        itemDelegate.grabOffset = Qt.point(mouse.x, mouse.y);
                        itemDelegate.dragPos = Qt.point(itemDelegate.x, itemDelegate.y);
                    }

                    onPositionChanged: (mouse) => {
                        if (pressed && (mouse.buttons & Qt.LeftButton)) {
                            if (!desktopWin.isDragging) {
                                desktopWin.isDragging = true;
                                desktopWin.draggingId = itemDelegate.itemId;
                            }
                            const globalX = itemDelegate.x + mouse.x;
                            const globalY = itemDelegate.y + mouse.y;
                            itemDelegate.dragPos = Qt.point(globalX - itemDelegate.grabOffset.x, globalY - itemDelegate.grabOffset.y);

                            // Calculate snap target
                            const gx = Math.max(0, Math.round((globalX - desktopWin.gridMargin - (desktopWin.cellW / 2)) / desktopWin.cellW));
                            const gy = Math.max(0, Math.round((globalY - desktopWin.gridMargin - (desktopWin.cellH / 2)) / desktopWin.cellH));
                            desktopWin.targetGridX = gx;
                            desktopWin.targetGridY = gy;
                        }
                    }

                    onReleased: (mouse) => {
                        if (desktopWin.isDragging && desktopWin.draggingId === itemDelegate.itemId) {
                            desktopWin.isDragging = false;
                            desktopWin.draggingId = "";
                            itemDelegate.curGridX = desktopWin.targetGridX;
                            itemDelegate.curGridY = desktopWin.targetGridY;
                            desktopWin.saveItemPos(itemDelegate.itemId, desktopWin.targetGridX, desktopWin.targetGridY);
                        }
                    }

                    onDoubleClicked: {
                        Quickshell.execDetached(["sh", "-c", itemDelegate.itemExec]);
                    }
                }
            }
        }
    }

    // ----------------------------------------------------------------- Desktop Background Area
    MouseArea {
        id: bgMouse
        anchors.fill: parent
        z: 0
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onPressed: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                desktopWin.openMenu(mouse.x, mouse.y);
            } else {
                ContextMenuState.hide();
                BarState.startOpen = false;
                BarState.quickOpen = false;
                desktopWin.selectedId = "";

                // Start rubber-band selection
                desktopWin.isSelecting = true;
                desktopWin.selectStartX = mouse.x;
                desktopWin.selectStartY = mouse.y;
                desktopWin.selectCurX = mouse.x;
                desktopWin.selectCurY = mouse.y;
                desktopWin.forceActiveFocus();
            }
        }

        onPositionChanged: (mouse) => {
            if (desktopWin.isSelecting) {
                desktopWin.selectCurX = mouse.x;
                desktopWin.selectCurY = mouse.y;
            }
        }

        onReleased: (mouse) => {
            if (desktopWin.isSelecting) {
                desktopWin.isSelecting = false;
            }
        }
    }

    // Context Menu
    function openMenu(x, y) {
        Quickshell.execDetached(["qs", "ipc", "-p", ShellPaths.appsHost, "call", "context", "hide"]);
        ContextMenuState.showAt(x, y, [
            {
                label: "Refresh",
                hint: "F5",
                action: function() { desktopWin.refresh(); }
            },
            { sep: true },
            {
                label: "Terminal",
                hint: "Super+T",
                action: function() { Quickshell.execDetached(["foot"]); }
            },
            {
                label: "Files",
                hint: "Super+E",
                action: function() { Quickshell.execDetached(["dssos-app", "files"]); }
            },
            {
                label: "Tasks",
                hint: "Ctrl+Shift+Esc",
                action: function() { Quickshell.execDetached(["dssos-app", "tasks"]); }
            },
            { sep: true },
            {
                label: "Display",
                action: function() { Quickshell.execDetached(["dssos-app", "settings"]); }
            }
        ], desktopWin.height);
    }
}
