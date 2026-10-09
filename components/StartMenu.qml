import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

// Start menu flyout, styled to match the bar and quick settings.
PanelWindow {
    id: menu

    anchors { bottom: true; left: true }
    margins { bottom: Style.flyoutBottom; left: 8 }
    implicitWidth: Math.min(600, Math.max(480, Math.round(screen.width * 0.32)))
    implicitHeight: Math.min(Math.round(screen.height * 0.75), 620)
    color: "transparent"
    visible: true
    mask: menu.shown ? openMask : closedMask
    exclusionMode: ExclusionMode.Ignore

    // ---- same palette ----
    readonly property color borderCol: Style.border
    readonly property color cardColor: Style.card
    readonly property color dimColor: Style.dim
    readonly property color green: Style.green
    readonly property color surface: Style.surface

    property bool shown: false
    // true while the slide-out runs: card is visible but dead (no mask, no clicks)
    property bool closing: false
    property string query: ""

    // sorted once per app-database change, filtered per keystroke
    // (GridView + ScriptModel keep delegates for unchanged rows)
    readonly property var sortedApps: DesktopEntries.applications.values
        .filter(e => !e.noDisplay)
        .sort((a, b) => a.name.localeCompare(b.name))
    readonly property var apps: {
        const q = menu.query.trim().toLowerCase();
        if (q === "") return menu.sortedApps;
        return menu.sortedApps.filter(e =>
            e.name.toLowerCase().includes(q) ||
            (e.genericName ?? "").toLowerCase().includes(q) ||
            (e.comment ?? "").toLowerCase().includes(q));
    }

    HyprlandFocusGrab {
        windows: [menu]
        active: menu.shown
        onCleared: BarState.startOpen = false
    }

    Region { id: openMask; item: card }
    Region { id: closedMask; width: 0; height: 0 }

    // slide up from the bar
    NumberAnimation {
        id: openAnim
        target: card
        property: "y"
        to: 0
        duration: Style.slideIn
        easing.type: Easing.OutCubic
    }
    NumberAnimation {
        id: closeAnim
        target: card
        property: "y"
        to: menu.height
        duration: Style.slideOut
        easing.type: Easing.InCubic
        onFinished: menu.closing = false
    }

    Connections {
        target: BarState
        function onStartOpenChanged() {
            if (BarState.startOpen) {
                closeAnim.stop();
                // reset offscreen only if fully gone; mid-close reopens glide back up
                if (!menu.shown && !menu.closing) card.y = menu.height;
                menu.closing = false;
                menu.query = "";
                search.text = "";
                menu.shown = true;
                openAnim.restart();
                search.forceActiveFocus();
            } else if (menu.shown) {
                openAnim.stop();
                menu.shown = false;   // drop the input mask NOW, card keeps sliding
                menu.closing = true;
                closeAnim.restart();
            }
        }
    }

    function launch(entry) {
        if (entry.runInTerminal) {
            // execute() won't open a terminal for Terminal=true apps;
            // entry.command may still carry %U-style field codes, drop them
            const argv = ["kitty", "-e"];
            for (const a of entry.command) {
                if (/^%[a-zA-Z]$/.test(a)) { continue; }
                argv.push(a);
            }
            Quickshell.execDetached(argv);
        } else {
            entry.execute();
        }
        BarState.startOpen = false;
    }
    function launchFirst() {
        if (menu.apps.length > 0) menu.launch(menu.apps[grid.currentIndex]);
    }

    // ================= components =================
    component PowerButton: Rectangle {
        id: pb
        property string icon
        property var cmd
        // destructive buttons arm on first click (red ~3s), fire on second
        property bool confirm: false
        property bool armed: false
        property color hoverColor: Style.cardHi
        Layout.preferredWidth: 40
        Layout.preferredHeight: 40
        radius: 12
        color: pb.armed ? Style.dangerDeep : (pArea.containsMouse ? pb.hoverColor : menu.cardColor)
        Behavior on color { ColorAnimation { duration: 120 } }

        Timer {
            id: disarm
            interval: 3000
            onTriggered: pb.armed = false
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: Style.text
            opacity: pArea.pressed ? Style.press : 0
            Behavior on opacity { NumberAnimation { duration: 100 } }
        }
        Image {
            anchors.centerIn: parent
            width: 18; height: 18
            sourceSize.width: 36; sourceSize.height: 36
            source: "../assets/icons/" + pb.icon + ".svg"
        }
        MouseArea {
            id: pArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (pb.confirm && !pb.armed) { pb.armed = true; disarm.restart(); return; }
                BarState.startOpen = false;
                Quickshell.execDetached(pb.cmd);
            }
        }
    }

    // ================= card =================
    Item {
        id: card
        width: parent.width
        height: parent.height
        y: menu.height
        visible: menu.shown || menu.closing
        enabled: menu.shown && !menu.closing

        Rectangle {
            anchors.fill: parent
            radius: 14
            color: menu.surface
            border.width: 1
            border.color: menu.borderCol
        }

        ColumnLayout {
            anchors { fill: parent; margins: 16 }
            spacing: 12

            // search
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                radius: 22
                color: menu.cardColor

                RowLayout {
                    anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
                    spacing: 10
                    Image {
                        width: 13; height: 13
                        sourceSize.width: 26; sourceSize.height: 26
                        source: "../assets/icons/search.svg"
                    }
                    TextInput {
                        id: search
                        Layout.fillWidth: true
                        color: Style.text
                        font.pixelSize: 14
                        clip: true
                        selectByMouse: true
                        onTextChanged: { menu.query = text; grid.currentIndex = 0; scrollAnim.stop(); grid.targetY = 0; grid.contentY = 0; }
                        Keys.onEscapePressed: BarState.startOpen = false
                        Keys.onDownPressed: grid.moveCurrentIndexDown()
                        Keys.onUpPressed: grid.moveCurrentIndexUp()
                        Keys.onLeftPressed: event => { if (text === "") grid.moveCurrentIndexLeft(); else event.accepted = false; }
                        Keys.onRightPressed: event => { if (text === "") grid.moveCurrentIndexRight(); else event.accepted = false; }
                        Keys.onReturnPressed: menu.launchFirst()
                        Keys.onEnterPressed: menu.launchFirst()
                        Text {
                            visible: search.text === ""
                            text: "Search apps"
                            color: menu.dimColor
                            font.pixelSize: 14
                        }
                    }
                }
            }

            // app grid
            GridView {
                id: grid
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                cellWidth: Math.floor(width / 5)
                cellHeight: 92
                model: ScriptModel { values: menu.apps }
                currentIndex: 0
                boundsBehavior: Flickable.StopAtBounds
                cacheBuffer: cellHeight * 2
                // smooth wheel scroll: accumulate a target, glide to it.
                // cheap on GPU: one contentY anim, delegates pre-cached, no re-layout.
                property real targetY: 0
                NumberAnimation {
                    id: scrollAnim
                    target: grid
                    property: "contentY"
                    duration: 180
                    easing.type: Easing.OutCubic
                }
                onMovementStarted: { scrollAnim.stop(); targetY = contentY; }
                WheelHandler {
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: event => {
                        const step = event.pixelDelta.y !== 0 ? event.pixelDelta.y : event.angleDelta.y;
                        const maxY = Math.max(0, grid.contentHeight - grid.height);
                        if (!scrollAnim.running) grid.targetY = grid.contentY;
                        grid.targetY = Math.max(0, Math.min(maxY, grid.targetY - step));
                        scrollAnim.to = grid.targetY;
                        scrollAnim.restart();
                        event.accepted = true;
                    }
                }

                delegate: Item {
                    id: cell
                    required property var modelData
                    required property int index
                    width: grid.cellWidth
                    height: grid.cellHeight

                    Rectangle {
                        anchors { fill: parent; margins: 3 }
                        radius: 12
                        color: (cell.GridView.isCurrentItem || cArea.containsMouse) ? menu.cardColor : "transparent"
                        Behavior on color { ColorAnimation { duration: 100 } }

                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            color: Style.text
                            opacity: cArea.pressed ? Style.press : 0
                            Behavior on opacity { NumberAnimation { duration: 100 } }
                        }

                        ColumnLayout {
                            anchors { fill: parent; margins: 6 }
                            spacing: 6
                            Item { Layout.fillHeight: true }
                            // letter placeholder behind the icon: covers slow loads
                            // and entries with no usable icon instead of a blank cell
                            Item {
                                Layout.alignment: Qt.AlignHCenter
                                Layout.preferredWidth: 40
                                Layout.preferredHeight: 40
                                Text {
                                    anchors.centerIn: parent
                                    text: cell.modelData.name.charAt(0).toUpperCase()
                                    color: Style.dim
                                    font.pixelSize: 22
                                    font.bold: true
                                }
                                Image {
                                    id: iconImg
                                    anchors.fill: parent
                                    sourceSize: Qt.size(80, 80)
                                    source: Quickshell.iconPath(cell.modelData.icon, "application-x-executable")
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                    // hide broken images instead of showing a blank frame
                                    visible: status !== Image.Error
                                }
                            }
                            Text {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                text: cell.modelData.name
                                color: Style.text
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }
                            Item { Layout.fillHeight: true }
                        }
                        MouseArea {
                            id: cArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: menu.launch(cell.modelData)
                        }
                    }
                }
            }

            // footer: user + power
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    radius: 20
                    color: menu.green
                    Text { anchors.centerIn: parent; text: "S"; color: Style.text; font.pixelSize: 16; font.bold: true }
                }
                Text {
                    Layout.fillWidth: true
                    text: "saad"
                    color: Style.text
                    font.pixelSize: 13
                    font.bold: true
                }
                PowerButton { icon: "lock"; cmd: ["loginctl", "lock-session"] }
                PowerButton { icon: "rotate-cw"; cmd: ["systemctl", "reboot"]; confirm: true }
                PowerButton { icon: "power"; cmd: ["systemctl", "poweroff"]; confirm: true; hoverColor: Style.dangerDeep }
            }
        }
    }
}
