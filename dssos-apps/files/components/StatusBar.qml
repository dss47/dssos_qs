import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import files

Rectangle {
    id: root

    property int itemCount: 0
    property var fileInfo: null
    property string freeSpaceText: "Checking disk..."
    // Feedback for create / rename / trash / warnings, supplied by Files.qml.
    property string toast: ""
    property bool toastIsError: false

    height: Theme.statusBarHeight
    color: Theme.rail

    // Séparateur supérieur 1px
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Theme.divider
    }

    // Processus pour interroger l'espace disque réel
    Process {
        id: dfProc
        command: ["df", "-h", Paths.home]
        // Started once on load and then re-armed by a 15s timer, whether
          // or not the Files window was on screen: four df processes a
          // minute for a status bar nobody could see.
          running: root.visible
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const lines = text.trim().split("\n");
                    if (lines.length >= 2) {
                        const parts = lines[1].split(/\s+/);
                        if (parts.length >= 4) {
                            root.freeSpaceText = parts[3] + " free of " + parts[1];
                        }
                    }
                } catch(e) {}
            }
        }
    }

    Timer {
        interval: 15000
        running: true
        repeat: true
        onTriggered: dfProc.running = true
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 18

        // Message toast transitoire (ex: "Select an item first", "Folder created")
        Text {
            visible: root.toast !== ""
            text: root.toast
            color: root.toastIsError ? Theme.danger : Theme.accent
            font.pixelSize: Theme.fontSizeHeader
            font.weight: Font.Medium
            font.family: Theme.fontFamily
        }

        // Nombre d'éléments (masqué si un toast est affiché pour éviter toute collision)
        Text {
            visible: root.toast === ""
            text: root.itemCount + (root.itemCount > 1 ? " items" : " item")
            color: Theme.muted
            font.pixelSize: Theme.fontSizeHeader
            font.family: Theme.fontFamily
        }

        // Détails de la sélection (masqué si un toast est affiché)
        Text {
            visible: root.toast === "" && root.fileInfo !== null
            text: root.fileInfo ? ("1 selected, " + root.fileInfo.size) : ""
            color: Theme.muted
            font.pixelSize: Theme.fontSizeHeader
            font.family: Theme.fontFamily
        }

        Item { Layout.fillWidth: true }

        // Espace libre sur le disque (toujours à droite)
        Text {
            text: root.freeSpaceText
            color: Theme.muted
            font.pixelSize: Theme.fontSizeHeader
            font.family: Theme.fontFamily
        }
    }
}
