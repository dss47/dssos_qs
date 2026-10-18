import QtQuick
import QtQuick.Layouts
import Quickshell
import files

Rectangle {
    id: root

    property string currentPath: ""
    signal locationSelected(string path)
    signal contextMenuRequested(real globalX, real globalY, var item)

    width: Theme.sidebarWidth
    implicitWidth: Theme.sidebarWidth
    Layout.preferredWidth: Theme.sidebarWidth
    color: Theme.side

    // Séparateur vertical droit 1px
    Rectangle {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: 1
        color: Theme.dividerSide
    }

    // Comes from StandardPaths via the Paths singleton, so "Home" is always
    // the logged-in user's home rather than a hardcoded /home/<someone>.
    readonly property string homeDir: Paths.home

    // Created up-front so every place resolves to its own directory; the model is
    // rebuilt once that finishes, because until then StandardPaths may report
    // a fallback path (e.g. Videos -> Desktop) that would highlight two rows.
    readonly property var sections: [
        {
            title: "Places",
            items: Paths.standardPlaces()
        },
        {
            title: "Devices",
            items: [
                { name: "System", icon: "drive-harddisk", path: "/", count: "" }
            ]
        },
        {
            title: "Network",
            items: [
                { name: "Network", icon: "network-workgroup", path: "/mnt", count: "" }
            ]
        }
    ]

    Flickable {
        anchors.fill: parent
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        contentHeight: sideColumn.implicitHeight
        clip: true

        ColumnLayout {
            id: sideColumn
            width: parent.width
            spacing: 0

            Repeater {
                model: root.sections

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    // Titre de section (<h6>)
                    Text {
                        text: modelData.title
                        color: Theme.muted
                        font.pixelSize: Theme.fontSizeHeader
                        font.weight: Font.DemiBold
                        font.family: Theme.fontFamily
                        Layout.fillWidth: true
                        Layout.leftMargin: 16
                        Layout.rightMargin: 16
                        Layout.topMargin: index === 0 ? 0 : 12
                        Layout.bottomMargin: 6
                    }

                    // Éléments de la section
                    Repeater {
                        model: modelData.items

                        Rectangle {
                            id: itemRow
                            Layout.fillWidth: true
                            Layout.preferredHeight: 32

                            readonly property bool isSelected: {
                                const p1 = root.currentPath.replace(/\/+$/, "");
                                const p2 = modelData.path.replace(/\/+$/, "");
                                return p1 === p2;
                            }

                            color: isSelected ? Theme.selected : (itemMouse.containsMouse ? Theme.rowHover : "transparent")

                            // Barre d'accentuation verte 3px à gauche pour la sélection
                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: 3
                                color: Theme.accent
                                visible: itemRow.isSelected
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                spacing: 10

                                Image {
                                    sourceSize: Qt.size(18, 18)
                                    source: Quickshell.iconPath(modelData.icon, "folder")
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Text {
                                    text: modelData.name
                                    color: itemRow.isSelected ? Theme.text : Theme.muted
                                    font.pixelSize: Theme.fontSizeNormal
                                    font.family: Theme.fontFamily
                                    Layout.alignment: Qt.AlignVCenter
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    // `count` is optional: a place with no
                                    // count simply renders nothing. Use a
                                    // default so an absent field cannot assign
                                    // undefined into a QString.
                                    text: modelData.count !== undefined
                                          ? modelData.count : ""
                                    color: Theme.muted
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.family: Theme.fontFamily
                                    visible: text !== ""
                                    Layout.alignment: Qt.AlignVCenter
                                }
                            }

                            MouseArea {
                                id: itemMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onPressed: (mouse) => {
                                    if (mouse.button === Qt.RightButton) {
                                        var pt = mapToItem(null, mouse.x, mouse.y);
                                        root.contextMenuRequested(pt.x, pt.y, modelData);
                                    }
                                }
                                onClicked: (mouse) => {
                                    if (mouse.button === Qt.LeftButton) {
                                        if (modelData.path) Paths.ensureDirectory(modelData.path);
                                        root.locationSelected(modelData.path);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
