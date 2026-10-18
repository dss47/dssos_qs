import QtQuick
import QtQuick.Layouts
import files
import common

Rectangle {
    id: root

    property var fileInfo: null
    property string currentPath: ""
    signal openRequested(string path)

    width: Theme.previewWidth
    color: Theme.side

    // Séparateur vertical gauche 1px
    Rectangle {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        width: 1
        color: Theme.dividerSide
    }

    readonly property bool hasSelection: root.fileInfo !== null
    readonly property bool isImage: {
        if (!hasSelection || root.fileInfo.isDir) return false;
        const n = (root.fileInfo.name || "").toLowerCase();
        return n.endsWith(".png") || n.endsWith(".jpg") || n.endsWith(".jpeg") ||
               n.endsWith(".svg") || n.endsWith(".webp") || n.endsWith(".gif");
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 0
        visible: root.hasSelection

        // Zone aperçu (130px, fond card #131313)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 130
            color: Theme.card

            // Image réelle si fichier image
            Image {
                anchors.fill: parent
                anchors.margins: 6
                visible: root.isImage
                source: root.hasSelection && root.isImage ? ("file://" + root.fileInfo.path) : ""
                sourceSize.width: 256
                sourceSize.height: 256
                fillMode: Image.PreserveAspectFit
                asynchronous: true
            }

            // Grande icône si non-image ou dossier
            FileIcon {
                anchors.centerIn: parent
                visible: !root.isImage
                fileName: root.hasSelection ? root.fileInfo.name : ""
                isDir: root.hasSelection ? root.fileInfo.isDir : false
                size: 44
            }
        }

        Item { Layout.preferredHeight: 12 }

        // Nom du fichier / dossier
        Text {
            Layout.fillWidth: true
            text: root.hasSelection ? root.fileInfo.name : ""
            color: Theme.text
            font.pixelSize: Theme.fontSizeTitle
            font.weight: Font.DemiBold
            font.family: Theme.fontFamily
            wrapMode: Text.WrapAnywhere
            maximumLineCount: 2
            elide: Text.ElideRight
        }

        Item { Layout.preferredHeight: 10 }

        // Ligne Type
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            color: "transparent"
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.divider }
            RowLayout {
                anchors.fill: parent
                Text { text: "Type"; color: Theme.muted; font.pixelSize: Theme.fontSizeNormal; font.family: Theme.fontFamily }
                Item { Layout.fillWidth: true }
                Text { text: root.hasSelection ? root.fileInfo.type : ""; color: Theme.text; font.pixelSize: Theme.fontSizeNormal; font.family: Theme.fontFamily }
            }
        }

        // Ligne Size
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            color: "transparent"
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.divider }
            RowLayout {
                anchors.fill: parent
                Text { text: "Size"; color: Theme.muted; font.pixelSize: Theme.fontSizeNormal; font.family: Theme.fontFamily }
                Item { Layout.fillWidth: true }
                Text { text: root.hasSelection ? root.fileInfo.size : ""; color: Theme.text; font.pixelSize: Theme.fontSizeNormal; font.family: Theme.fontFamily }
            }
        }

        // Ligne Modified
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            color: "transparent"
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.divider }
            RowLayout {
                anchors.fill: parent
                Text { text: "Modified"; color: Theme.muted; font.pixelSize: Theme.fontSizeNormal; font.family: Theme.fontFamily }
                Item { Layout.fillWidth: true }
                Text { text: root.hasSelection ? root.fileInfo.modified : ""; color: Theme.text; font.pixelSize: Theme.fontSizeNormal; font.family: Theme.fontFamily }
            }
        }

        // Ligne Location
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            color: "transparent"
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.divider }
            RowLayout {
                anchors.fill: parent
                Text { text: "Location"; color: Theme.muted; font.pixelSize: Theme.fontSizeNormal; font.family: Theme.fontFamily }
                Item { Layout.fillWidth: true }
                Text {
                    text: Paths.tilde(root.currentPath)
                    color: Theme.text
                    font.pixelSize: Theme.fontSizeNormal
                    font.family: Theme.fontFamily
                    elide: Text.ElideMiddle
                    Layout.maximumWidth: 120
                }
            }
        }

        Item { Layout.fillHeight: true }

        // Boutons Open et Share
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            spacing: 6

            DssButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                text: "Open"
                variant: "accent"
                onClicked: {
                    if (root.hasSelection) {
                        root.openRequested(root.fileInfo.path);
                    }
                }
            }

            DssButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                text: "Share"
                variant: "card"
                onClicked: { }
            }
        }
    }

    // État vide quand aucun élément n'est sélectionné
    Text {
        anchors.centerIn: parent
        visible: !root.hasSelection
        text: "Select a file to preview"
        color: Theme.muted
        font.pixelSize: Theme.fontSizeNormal
        font.family: Theme.fontFamily
    }
}
