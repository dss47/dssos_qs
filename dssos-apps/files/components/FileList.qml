import QtQuick
import QtQuick.Layouts
import files
import common

Item {
    id: root

    property var model: null
    property int selectedIndex: -1
    property string searchQuery: ""

    // Sort state, owned by Files.qml (it drives the FolderListModel).
    // "Name" | "Date" | "Size" | "Type"
    property string sortField: "Name"
    property bool sortAscending: true

    signal fileActivated(int index, string filePath, bool isDir)
    signal selectionChanged(int index, var fileInfo)
    signal sortFieldSelected(string field)
    signal sortOrderToggled()
    signal contextMenuRequested(real globalX, real globalY, var fileInfo)
    signal emptySpaceContextMenuRequested(real globalX, real globalY)
    property bool renaming: false
    property string renameValue: ""
    property bool isTrash: false
    signal renameCommitted(string newName)
    signal renameCancelled()
    property bool allSelected: false
    signal selectAllRequested()
    signal copyRequested()
    signal cutRequested()
    signal pasteRequested()
    signal undoRequested()
    signal renameRequested()
    signal deleteRequested(bool permanent)
    signal newFolderRequested()
    signal goUpRequested()
    signal goBackRequested()
    signal goForwardRequested()

    focus: true
    onRenamingChanged: if (!renaming) root.forceActiveFocus()
    Keys.onPressed: (event) => {
        console.log("--> FileList key:", event.key, "modifiers:", event.modifiers);
        if (root.renaming) return;
        if (event.modifiers & Qt.ControlModifier) {
            if (event.key === Qt.Key_C) {
                root.copyRequested();
                event.accepted = true;
            } else if (event.key === Qt.Key_X) {
                root.cutRequested();
                event.accepted = true;
            } else if (event.key === Qt.Key_V) {
                root.pasteRequested();
                event.accepted = true;
            } else if (event.key === Qt.Key_A) {
                root.selectAllRequested();
                event.accepted = true;
            } else if (event.key === Qt.Key_Z) {
                root.undoRequested();
                event.accepted = true;
            } else if (event.key === Qt.Key_N) {
                root.newFolderRequested();
                event.accepted = true;
            }
        } else if (event.modifiers & Qt.AltModifier) {
            if (event.key === Qt.Key_Left) {
                root.goBackRequested();
                event.accepted = true;
            } else if (event.key === Qt.Key_Right) {
                root.goForwardRequested();
                event.accepted = true;
            }
        } else if (event.key === Qt.Key_Backspace) {
            root.goUpRequested();
            event.accepted = true;
        } else if (event.key === Qt.Key_F2) {
            if (!root.isTrash && root.selectedIndex >= 0) {
                root.renameRequested();
                event.accepted = true;
            }
        } else if (event.key === Qt.Key_Delete) {
            if (root.selectedIndex >= 0) {
                root.deleteRequested(event.modifiers & Qt.ShiftModifier);
                event.accepted = true;
            }
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (root.selectedIndex >= 0 && model) {
                const it = root.getItem(root.selectedIndex);
                if (it) {
                    root.fileActivated(root.selectedIndex, it.path, it.isDir);
                    event.accepted = true;
                }
            }
        } else if (event.key === Qt.Key_Up) {
            if (root.selectedIndex > 0) {
                root.selectIndex(root.selectedIndex - 1);
                event.accepted = true;
            }
        } else if (event.key === Qt.Key_Down) {
            if (model && root.selectedIndex < model.count - 1) {
                root.selectIndex(root.selectedIndex + 1);
                event.accepted = true;
            }
        }
    }

    // Formatage de la taille
    function formatSize(bytes, isDir): string {
        if (isDir) return "—";
        if (bytes < 1024) return bytes + " B";
        if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + " KB";
        if (bytes < 1024 * 1024 * 1024) return (bytes / (1024 * 1024)).toFixed(1) + " MB";
        return (bytes / (1024 * 1024 * 1024)).toFixed(1) + " GB";
    }

    // Formatage de la date de modification
    function formatModified(date): string {
        if (!date || isNaN(date.getTime())) return "—";
        const now = new Date();
        const isToday = now.toDateString() === date.toDateString();
        const hours = ("0" + date.getHours()).slice(-2);
        const minutes = ("0" + date.getMinutes()).slice(-2);
        if (isToday) return "Today, " + hours + ":" + minutes;
        const yesterday = new Date(now);
        yesterday.setDate(now.getDate() - 1);
        if (yesterday.toDateString() === date.toDateString()) return "Yesterday, " + hours + ":" + minutes;
        const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        return date.getDate() + " " + months[date.getMonth()];
    }

    // Formatage du type
    function formatType(fileName, isDir): string {
        if (isDir) return "Folder";
        const dot = fileName.lastIndexOf(".");
        if (dot === -1) return "File";
        const ext = fileName.substring(dot + 1).toLowerCase();
        switch (ext) {
            case "png": return "PNG image";
            case "jpg":
            case "jpeg": return "JPEG image";
            case "svg": return "SVG image";
            case "gif": return "GIF image";
            case "webp": return "WebP image";
            case "pdf": return "PDF document";
            case "txt": return "Text";
            case "md": return "Markdown";
            case "c":
            case "cpp":
            case "h":
            case "hpp": return "C++ source";
            case "py": return "Python script";
            case "js":
            case "ts": return "JavaScript";
            case "qml": return "QML source";
            case "html": return "HTML document";
            case "css": return "CSS stylesheet";
            case "json": return "JSON document";
            case "sh": return "Shell script";
            case "zip":
            case "tar":
            case "gz":
            case "xz":
            case "zst": return "Archive";
            case "mp3":
            case "ogg":
            case "wav": return "Audio";
            case "mp4":
            case "mkv":
            case "webm": return "Video";
            default: return ext.toUpperCase() + " file";
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // En-tête fixe (30px)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.listHeaderHeight
            color: Theme.bg

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: Theme.divider
            }

            // Windows-style sortable column headers: clicking a header sorts by that
            // column, clicking the active one flips the direction. The arrow
            // sits next to the label of the column currently being sorted.
            //
            // Widths are given explicitly per column (w = -1 means "take the
            // remaining space") rather than with conditional Layout.fillWidth
            // inside an inline component -- that combination collapsed every
            // header to zero width and stacked them on top of each other.
            RowLayout {
                id: headerRow
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 0

                Repeater {
                    model: [
                        { label: "Name",          field: "Name", w: -1 },
                        { label: "Date modified", field: "Date", w: 150 },
                        { label: "Size",          field: "Size", w: 90 },
                        { label: "Type",          field: "Type", w: 110 }
                    ]

                    delegate: Rectangle {
                        id: hdr
                        required property var modelData

                        readonly property bool active: root.sortField === hdr.modelData.field
                        readonly property bool growable: hdr.modelData.w < 0

                        Layout.fillWidth: hdr.growable
                        Layout.preferredWidth: hdr.growable ? 0 : hdr.modelData.w
                        Layout.minimumWidth: hdr.growable ? 160 : hdr.modelData.w
                        Layout.preferredHeight: Theme.listHeaderHeight
                        color: hdrMouse.containsMouse ? Theme.rowHover : "transparent"

                        RowLayout {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4

                            Text {
                                text: hdr.modelData.label
                                color: hdr.active ? Theme.text : Theme.muted
                                font.pixelSize: Theme.fontSizeHeader
                                font.family: Theme.fontFamily
                            }
                            Text {
                                visible: hdr.active
                                text: root.sortAscending ? "↑" : "↓"
                                color: Theme.accent
                                font.pixelSize: Theme.fontSizeNormal
                                font.family: Theme.fontFamily
                            }
                        }

                        MouseArea {
                            id: hdrMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.sortField === hdr.modelData.field) {
                                    root.sortOrderToggled();
                                } else {
                                    // Names read best A-Z; size and date are
                                    // most useful biggest/newest first.
                                    root.sortAscending = (hdr.modelData.field === "Name");
                                    root.sortFieldSelected(hdr.modelData.field);
                                }
                            }
                        }
                    }
                }
            }
        }

        // Liste déroulante virtualisée
        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: root.model
            boundsBehavior: Flickable.StopAtBounds

            MouseArea {
                anchors.fill: parent
                z: -1
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onPressed: (mouse) => {
                    if (mouse.button === Qt.RightButton) {
                        var pt = mapToItem(null, mouse.x, mouse.y);
                        root.emptySpaceContextMenuRequested(pt.x, pt.y);
                    } else {
                        root.selectedIndex = -1;
                        root.selectionChanged(-1, null);
                    }
                }
            }

            // Barre de défilement partagée
            DssScrollBar {
                target: listView
            }

            delegate: Rectangle {
                id: rowRect
                width: listView.width
                height: Theme.listRowHeight

                // Filtrage si recherche active
                visible: {
                    if (root.searchQuery === "") return true;
                    return fileName.toLowerCase().includes(root.searchQuery.toLowerCase());
                }
                // Si non visible en recherche, hauteur 0
                Binding on height {
                    when: !rowRect.visible
                    value: 0
                }

                readonly property bool isSelected: root.allSelected || index === root.selectedIndex
                readonly property bool isRenamingThis: root.renaming && (index === root.selectedIndex)
                color: isSelected ? Theme.selected : (rowMouse.containsMouse ? Theme.rowHover : "transparent")

                // Barre d'accentuation verte 3px à gauche pour la sélection
                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 3
                    color: Theme.accent
                    visible: rowRect.isSelected
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 0

                    // Nom + Icône
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        FileIcon {
                            fileName: model.fileName
                            isDir: model.fileIsDir
                            size: 18
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Text {
                            visible: !rowRect.isRenamingThis
                            text: model.fileName
                            color: rowRect.isSelected ? "#ffffff" : Theme.text
                            font.pixelSize: Theme.fontSizeNormal
                            font.family: Theme.fontFamily
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Rectangle {
                            visible: rowRect.isRenamingThis
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0
                            Layout.preferredHeight: 24
                            Layout.alignment: Qt.AlignVCenter
                            color: "#000000"
                            border.width: 1
                            border.color: Theme.accent
                            radius: 0

                            TextInput {
                                id: inlineInput
                                anchors.fill: parent
                                anchors.leftMargin: 6
                                anchors.rightMargin: 6
                                verticalAlignment: TextInput.AlignVCenter
                                color: "#ffffff"
                                font.pixelSize: Theme.fontSizeNormal
                                font.family: Theme.fontFamily
                                selectByMouse: true
                                clip: true
                                text: root.renameValue

                                focus: true
                                Component.onCompleted: if (visible) setupFocus()
                                onVisibleChanged: if (visible) setupFocus()
                                function setupFocus() {
                                    inlineInput.text = root.renameValue;
                                    Qt.callLater(function() {
                                        inlineInput.forceActiveFocus();
                                        var dot = inlineInput.text.lastIndexOf(".");
                                        if (!model.fileIsDir && dot > 0) {
                                            inlineInput.select(0, dot);
                                        } else {
                                            inlineInput.selectAll();
                                        }
                                    });
                                }
                                Keys.onReturnPressed: (event) => { root.renameCommitted(text); event.accepted = true; }
                                Keys.onEnterPressed: (event) => { root.renameCommitted(text); event.accepted = true; }
                                Keys.onEscapePressed: (event) => { root.renameCancelled(); event.accepted = true; }
                            }
                        }

                    }

                    // Modified
                    Text {
                        text: root.formatModified(model.fileModified)
                        color: Theme.muted
                        font.pixelSize: Theme.fontSizeNormal
                        font.family: Theme.fontFamily
                        Layout.preferredWidth: 150
                        Layout.alignment: Qt.AlignVCenter
                    }

                    // Size
                    Text {
                        text: root.formatSize(model.fileSize, model.fileIsDir)
                        color: Theme.muted
                        font.pixelSize: Theme.fontSizeNormal
                        font.family: Theme.fontFamily
                        Layout.preferredWidth: 90
                        Layout.alignment: Qt.AlignVCenter
                    }

                    // Type
                    Text {
                        text: root.formatType(model.fileName, model.fileIsDir)
                        color: Theme.muted
                        font.pixelSize: Theme.fontSizeNormal
                        font.family: Theme.fontFamily
                        Layout.preferredWidth: 110
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                Component.onCompleted: {
                    if (index === 0 && root.selectedIndex === -1) {
                        root.selectedIndex = 0;
                        root.selectionChanged(0, {
                            name: model.fileName,
                            path: model.filePath,
                            isDir: model.fileIsDir,
                            size: root.formatSize(model.fileSize, model.fileIsDir),
                            modified: root.formatModified(model.fileModified),
                            type: root.formatType(model.fileName, model.fileIsDir)
                        });
                    }
                }

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !rowRect.isRenamingThis
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onPressed: (mouse) => {
                        root.forceActiveFocus();
                        if (mouse.button === Qt.RightButton) {
                            var info = {
                                name: model.fileName,
                                path: model.filePath,
                                isDir: model.fileIsDir,
                                size: root.formatSize(model.fileSize, model.fileIsDir),
                                modified: root.formatModified(model.fileModified),
                                type: root.formatType(model.fileName, model.fileIsDir)
                            };
                            root.selectedIndex = index;
                            root.selectionChanged(index, info);
                            var pt = mapToItem(null, mouse.x, mouse.y);
                            root.contextMenuRequested(pt.x, pt.y, info);
                        }
                    }

                    onClicked: (mouse) => {
                        if (mouse.button === Qt.LeftButton) {
                            var info = {
                                name: model.fileName,
                                path: model.filePath,
                                isDir: model.fileIsDir,
                                size: root.formatSize(model.fileSize, model.fileIsDir),
                                modified: root.formatModified(model.fileModified),
                                type: root.formatType(model.fileName, model.fileIsDir)
                            };
                            root.selectedIndex = index;
                            root.selectionChanged(index, info);
                        }
                    }

                    onDoubleClicked: (mouse) => {
                        if (mouse.button === Qt.LeftButton) {
                            root.fileActivated(index, model.filePath, model.fileIsDir);
                        }
                    }
                }
            }
        }
    }

    function getItem(idx: int) {
        if (!model || idx < 0 || idx >= model.count) return null;
        if (model.get) {
            const fn = model.get(idx, "fileName") || "";
            const fp = model.get(idx, "filePath") || "";
            const isD = Boolean(model.get(idx, "fileIsDir"));
            const sz = model.get(idx, "fileSize") || 0;
            const mod = model.get(idx, "fileModified") || new Date();
            return {
                name: fn,
                path: fp,
                isDir: isD,
                size: formatSize(sz, isD),
                modified: formatModified(mod),
                type: formatType(fn, isD)
            };
        }
        return null;
    }

    function selectIndex(idx: int): void {
        if (!model || idx < 0 || idx >= model.count) return;
        selectedIndex = idx;
        const item = getItem(idx);
        if (item) {
            selectionChanged(idx, item);
        }
        listView.positionViewAtIndex(idx, ListView.Contain);
    }

    function selectFirst(): void {
        if (model && model.count > 0) {
            selectIndex(0);
        }
    }

    function handleRightClick(gx: real, gy: real): bool {
        var pt = listView.mapFromItem(null, gx, gy);
        if (pt.x >= 0 && pt.x <= listView.width && pt.y >= 0 && pt.y <= listView.height) {
            var cx = pt.x + listView.contentX;
            var cy = pt.y + listView.contentY;
            var idx = listView.indexAt(cx, cy);
            if (idx >= 0) {
                var item = root.getItem(idx);
                if (item && (root.searchQuery === "" || item.name.toLowerCase().includes(root.searchQuery.toLowerCase()))) {
                    root.selectedIndex = idx;
                    root.selectionChanged(idx, item);
                    root.contextMenuRequested(gx, gy, item);
                    return true;
                }
            }
            root.selectedIndex = -1;
            root.selectionChanged(-1, null);
            root.emptySpaceContextMenuRequested(gx, gy);
            return true;
        }
        return false;
    }
}
