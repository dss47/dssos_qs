import QtQuick
import QtQuick.Layouts
import files

Rectangle {
    id: root

    property string currentPath: ""
    property bool editing: false
    signal navigateTo(string path)

    height: 30
    color: Theme.control

    // Bordure inférieure 2px
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 2
        color: root.editing ? Theme.accent : Theme.divider
    }

    function parseSegments(): var {
        let clean = currentPath.replace(/\/+$/, "");
        if (clean === "") return [{ name: "/", path: "/" }];

        // Breadcrumbs inside the user's home start at "Home" rather than
        // spelling out /home/<username>. The home path itself comes from
        // StandardPaths via the Paths singleton.
        const home = Paths.home;

        if (clean === home) {
            return [{ name: "Home", path: home }];
        }

        if (clean.indexOf(home + "/") === 0) {
            let rel = clean.substring(home.length + 1);
            let parts = rel.split("/").filter(p => p.length > 0);
            let list = [{ name: "Home", path: home }];
            let accum = home;
            for (let i = 0; i < parts.length; ++i) {
                accum += "/" + parts[i];
                list.push({ name: parts[i], path: accum });
            }
            return list;
        }

        let parts = clean.split("/").filter(p => p.length > 0);
        let list = [{ name: "/", path: "/" }];
        let accum = "";
        for (let i = 0; i < parts.length; ++i) {
            accum += "/" + parts[i];
            list.push({ name: parts[i], path: accum });
        }
        return list;
    }

    readonly property var segments: parseSegments()

    // Mode affichage normal (fil d'Ariane)
    RowLayout {
        id: breadcrumbsRow
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4
        spacing: 2
        visible: !root.editing

        Repeater {
            model: root.segments

            RowLayout {
                spacing: 2
                Layout.alignment: Qt.AlignVCenter

                Rectangle {
                    id: segRect
                    Layout.preferredHeight: 22
                    implicitWidth: segText.implicitWidth + 14
                    color: segMouse.containsMouse ? Theme.selected : "transparent"

                    Text {
                        id: segText
                        anchors.centerIn: parent
                        text: modelData.name
                        color: (index === root.segments.length - 1) ? Theme.text : Theme.muted
                        font.pixelSize: Theme.fontSizeNormal
                        font.family: Theme.fontFamily
                    }

                    MouseArea {
                        id: segMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.navigateTo(modelData.path)
                    }
                }

                Text {
                    text: "›"
                    visible: index < root.segments.length - 1
                    color: "#444444"
                    font.pixelSize: 13
                    font.family: Theme.fontFamily
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }

        // Zone vide à droite pour basculer en mode édition
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            MouseArea {
                anchors.fill: parent
                onDoubleClicked: {
                    root.editing = true;
                    pathInput.text = root.currentPath;
                    pathInput.selectAll();
                    pathInput.forceActiveFocus();
                }
            }
        }
    }

    // Mode saisie manuelle de chemin (Ctrl+L)
    TextInput {
        id: pathInput
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        verticalAlignment: TextInput.AlignVCenter
        visible: root.editing
        color: Theme.text
        font.pixelSize: Theme.fontSizeNormal
        font.family: Theme.fontFamily
        selectByMouse: true
        selectionColor: Theme.accent
        selectedTextColor: "#000000"

        Keys.onEscapePressed: {
            root.editing = false;
        }

        onAccepted: {
            let p = text.trim();
            if (p.startsWith("~")) {
                // "~" expands to the logged-in user's home, not a fixed path.
                p = Paths.home + p.substring(1);
            }
            if (p.length > 0) {
                root.navigateTo(p);
            }
            root.editing = false;
        }
    }

    function startEditing(): void {
        root.editing = true;
        pathInput.text = root.currentPath;
        pathInput.selectAll();
        pathInput.forceActiveFocus();
    }
}
