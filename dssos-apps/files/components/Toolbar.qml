import QtQuick
import QtQuick.Layouts
import Quickshell
import files

Rectangle {
    id: root

    property string currentPath: ""
    property bool canGoBack: false
    property bool canGoForward: false
    property bool canGoUp: false
    property bool isGrid: false
    property string searchQuery: ""

    signal backClicked()
    signal forwardClicked()
    signal upClicked()
    signal navigateTo(string path)
    signal toggleView(bool grid)
    signal menuClicked()

    height: Theme.toolbarHeight
    color: Theme.bg

    // Séparateur inférieur 1px
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Theme.divider
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 6

        // Bouton Précédent (Back)
        Rectangle {
            Layout.preferredWidth: 30
            Layout.preferredHeight: 30
            color: backMouse.containsMouse && root.canGoBack ? Theme.selected : "transparent"
            opacity: root.canGoBack ? 1.0 : 0.35

            Image {
                anchors.centerIn: parent
                sourceSize: Qt.size(16, 16)
                source: Quickshell.iconPath("go-previous", "")
            }

            MouseArea {
                id: backMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: root.canGoBack ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: if (root.canGoBack) root.backClicked()
            }
        }

        // Bouton Suivant (Forward)
        Rectangle {
            Layout.preferredWidth: 30
            Layout.preferredHeight: 30
            color: fwdMouse.containsMouse && root.canGoForward ? Theme.selected : "transparent"
            opacity: root.canGoForward ? 1.0 : 0.35

            Image {
                anchors.centerIn: parent
                sourceSize: Qt.size(16, 16)
                source: Quickshell.iconPath("go-next", "")
            }

            MouseArea {
                id: fwdMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: root.canGoForward ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: if (root.canGoForward) root.forwardClicked()
            }
        }

        // Bouton Dossier parent (Up)
        Rectangle {
            Layout.preferredWidth: 30
            Layout.preferredHeight: 30
            color: upMouse.containsMouse && root.canGoUp ? Theme.selected : "transparent"
            opacity: root.canGoUp ? 1.0 : 0.35

            Image {
                anchors.centerIn: parent
                sourceSize: Qt.size(16, 16)
                source: Quickshell.iconPath("go-up", "")
            }

            MouseArea {
                id: upMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: root.canGoUp ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: if (root.canGoUp) root.upClicked()
            }
        }

        // Barre de chemin (PathBar)
        PathBar {
            id: pathBarItem
            Layout.fillWidth: true
            currentPath: root.currentPath
            onNavigateTo: path => root.navigateTo(path)
        }

        // Barre de recherche (Search)
        Rectangle {
            Layout.preferredWidth: 200
            Layout.preferredHeight: 30
            color: Theme.control

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 2
                color: searchInput.activeFocus ? Theme.accent : Theme.divider
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 6

                Image {
                    sourceSize: Qt.size(16, 16)
                    source: Quickshell.iconPath("edit-find", "")
                    opacity: 0.6
                }

                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.text
                    font.pixelSize: Theme.fontSizeNormal
                    font.family: Theme.fontFamily
                    selectByMouse: true
                    selectionColor: Theme.accent
                    selectedTextColor: "#000000"

                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        text: "Search"
                        color: Theme.muted
                        font.pixelSize: Theme.fontSizeNormal
                        font.family: Theme.fontFamily
                        visible: !searchInput.text && !searchInput.activeFocus
                    }

                    onTextChanged: {
                        root.searchQuery = text;
                    }
                }

                // Bouton effacer la recherche
                Text {
                    text: "×"
                    color: Theme.muted
                    font.pixelSize: 16
                    visible: searchInput.text.length > 0
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            searchInput.text = "";
                            root.searchQuery = "";
                        }
                    }
                }
            }
        }

        // Bascule Vue Liste
        Rectangle {
            Layout.preferredWidth: 30
            Layout.preferredHeight: 30
            color: !root.isGrid ? Theme.selected : (listMouse.containsMouse ? Theme.selected : "transparent")

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 2
                color: Theme.accent
                visible: !root.isGrid
            }

            Image {
                anchors.centerIn: parent
                sourceSize: Qt.size(16, 16)
                source: Quickshell.iconPath("view-list-details", "")
                opacity: !root.isGrid ? 1.0 : 0.6
            }

            MouseArea {
                id: listMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toggleView(false)
            }
        }

        // Bascule Vue Grille
        Rectangle {
            Layout.preferredWidth: 30
            Layout.preferredHeight: 30
            color: root.isGrid ? Theme.selected : (gridMouse.containsMouse ? Theme.selected : "transparent")

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 2
                color: Theme.accent
                visible: root.isGrid
            }

            Image {
                anchors.centerIn: parent
                sourceSize: Qt.size(16, 16)
                source: Quickshell.iconPath("view-grid", "")
                opacity: root.isGrid ? 1.0 : 0.6
            }

            MouseArea {
                id: gridMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toggleView(true)
            }
        }

        // Bouton Details (i)
        // Drawn rather than themed: a plain circle + "i" stays square at any
        // scale, follows the accent/border tokens, and does not depend on which
        // icon theme happens to be installed.
        Rectangle {
            id: detailsBtn
            Layout.preferredWidth: 30
            Layout.preferredHeight: 30
            color: menuMouse.containsMouse ? Theme.selected : "transparent"

            Rectangle {
                anchors.centerIn: parent
                width: 16
                height: 16
                radius: width / 2
                color: "transparent"
                border.width: 1
                border.color: detailsBtn.pressed ? Theme.accent : Theme.muted

                Text {
                    anchors.centerIn: parent
                    // Nudge down: an "i" is optically centred slightly low.
                    anchors.verticalCenterOffset: 0.5
                    text: "i"
                    color: detailsBtn.pressed ? Theme.accent : Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }
            }

            MouseArea {
                id: menuMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.menuClicked()
            }
        }
    }

    function focusPathInput(): void {
        pathBarItem.startEditing();
    }

    function focusSearch(): void {
        searchInput.forceActiveFocus();
    }
}
