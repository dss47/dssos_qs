import QtQuick
import QtQuick.Layouts
import tasks
import common

Item {
    id: root
    height: Theme.topBarHeight

    property string currentView: "ov"
    property string searchText: ""
    property int currentFilter: 0

    signal overviewClicked()
    signal searchChanged(string text)
    signal filterChanged(int filter)

    function focusSearch() {
        searchBox.focusInput();
    }

    // Bottom 1px divider
    Rectangle {
        width: parent.width
        height: 1
        anchors.bottom: parent.bottom
        color: Theme.dividerSide
        z: 10
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: 11
        anchors.bottomMargin: 11
        spacing: 10

        // 1. Overview Button (30x30)
        Rectangle {
            id: pcb
            Layout.preferredWidth: 30
            Layout.preferredHeight: 30
            color: root.currentView === "ov" ? Theme.selected : (pcbMouse.containsMouse ? Theme.cardHover : Theme.card)

            Canvas {
                id: monitorIcon
                anchors.centerIn: parent
                width: 18
                height: 18
                renderTarget: Canvas.FramebufferObject
                renderStrategy: Canvas.Cooperative

                property color iconColor: root.currentView === "ov" ? Theme.accent : Theme.muted

                onIconColorChanged: requestPaint()

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    ctx.strokeStyle = iconColor;
                    ctx.lineWidth = 1.6;
                    ctx.lineCap = "round";
                    ctx.lineJoin = "round";

                    // Screen: rect x=2, y=2, w=14, h=10
                    ctx.strokeRect(2, 2, 14, 10);
                    // Stand: vertical line (9, 12) -> (9, 15)
                    ctx.beginPath();
                    ctx.moveTo(9, 12);
                    ctx.lineTo(9, 15);
                    // Base: horizontal line (5, 15) -> (13, 15)
                    ctx.moveTo(5, 15);
                    ctx.lineTo(13, 15);
                    ctx.stroke();
                }
            }

            // 2px accent bottom indicator when in overview
            Rectangle {
                height: 2
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                color: Theme.accent
                visible: root.currentView === "ov"
            }

            MouseArea {
                id: pcbMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.overviewClicked()
            }
        }

        // 2. Shared Search Box (Flex, visible only when process view)
        DssSearchBox {
            id: searchBox
            Layout.fillWidth: true
            visible: root.currentView === "ps"
            placeholder: "Search"
            onSearchChanged: function(txt) {
                root.searchText = txt;
                root.searchChanged(txt);
            }
        }

        // Spacer when search is hidden on Overview
        Item {
            Layout.fillWidth: true
            visible: root.currentView === "ov"
        }

        // 3. Shared Segmented Filter (All / Apps / Background, visible only when process view)
        DssSegmented {
            id: filterSwitch
            visible: root.currentView === "ps"
            model: ["All", "Apps", "Background"]
            currentIndex: root.currentFilter
            onFilterChanged: function(idx, label) {
                root.currentFilter = idx;
                root.filterChanged(idx);
            }
        }
    }
}
