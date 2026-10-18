import QtQuick
import QtQuick.Layouts
import files
import common

Item {
    id: root

    property var model: null
    property int selectedIndex: -1
    property string searchQuery: ""

    // ---------------------------------------------------------------------
    // Why the grid filters the MODEL and not the delegate
    //
    // It used to do `delegate.visible = name.includes(searchQuery)`. A
    // GridView gives every index a fixed cell, so a hidden delegate leaves an
    // empty cell behind: searching "dossier" in a folder of twenty files
    // produced a grid with holes in it instead of a compact result.
    //
    // The filter has to change the delegate COUNT for the view to reflow, and
    // the count only follows the model. FolderListModel is a C++ type with no
    // filter hook (nameFilters keeps every directory), so the filtered rows are
    // copied into a plain JS array and that is what GridView gets as its
    // model. GridView still virtualises -- only the visible cells exist -- and
    // the rows now pack left to right with no gaps.
    property var rows: []

    function rebuildRows() {
        if (!model || !model.get) {
            rows = [];
            return;
        }
        const q = searchQuery.trim().toLowerCase();
        const out = [];
        for (let i = 0; i < model.count; ++i) {
            const fn = model.get(i, "fileName") || "";
            if (q !== "" && fn.toLowerCase().indexOf(q) === -1) continue;
            out.push({
                fileName: fn,
                filePath: model.get(i, "filePath") || "",
                fileIsDir: Boolean(model.get(i, "fileIsDir")),
                fileSize: model.get(i, "fileSize") || 0,
                fileModified: model.get(i, "fileModified") || new Date()
            });
        }
        rows = out;
    }

    onSearchQueryChanged: rebuildRows()
    onModelChanged: rebuildRows()
    Component.onCompleted: rebuildRows()

    // FolderListModel is a QAbstractListModel: countChanged is the signal that
    // actually fires when the directory listing changes.
    Connections {
        target: root.model
        function onCountChanged() { root.rebuildRows(); }
    }

    readonly property int rowCount: rows.length

    signal fileActivated(int index, string filePath, bool isDir)
    signal selectionChanged(int index, var fileInfo)
    signal contextMenuRequested(real globalX, real globalY, var fileInfo)
    signal emptySpaceContextMenuRequested(real globalX, real globalY)
    property bool renaming: false
    property string renameValue: ""
    property bool isTrash: false
    signal renameCommitted(string newName)
    signal renameCancelled()
    signal copyRequested()
    signal cutRequested()
    signal pasteRequested()
    property bool allSelected: false
    signal selectAllRequested()
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
        } else if (event.key === Qt.Key_Left) {
            if (root.selectedIndex > 0) {
                root.selectIndex(root.selectedIndex - 1);
                event.accepted = true;
            }
        } else if (event.key === Qt.Key_Right) {
            if (root.selectedIndex < rows.length - 1) {
                root.selectIndex(root.selectedIndex + 1);
                event.accepted = true;
            }
        } else if (event.key === Qt.Key_Up) {
            var cols = Math.max(1, Math.floor(gridView.width / gridView.cellWidth));
            if (root.selectedIndex - cols >= 0) {
                root.selectIndex(root.selectedIndex - cols);
                event.accepted = true;
            }
        } else if (event.key === Qt.Key_Down) {
            var cols = Math.max(1, Math.floor(gridView.width / gridView.cellWidth));
            if (root.selectedIndex + cols < rows.length) {
                root.selectIndex(root.selectedIndex + cols);
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
        // fileName is undefined for a row the model has not filled in yet;
        // lastIndexOf on it threw and took the whole Type column with it.
        if (!fileName) return "File";
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

    GridView {
        id: gridView
        anchors.fill: parent
        anchors.margins: 14
        cellWidth: 136
        cellHeight: 138
        clip: true
        // NOT root.model: that is the unfiltered FolderListModel, and feeding
        // it here is what produced the gaps.
        model: root.rows
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
            target: gridView
        }

        delegate: Item {
            id: cellItem
            width: 130
            height: 132

            readonly property bool isSelected: root.allSelected || index === root.selectedIndex
            readonly property bool isRenamingThis: root.renaming && (index === root.selectedIndex)

            Rectangle {
                anchors.fill: parent
                color: cellItem.isSelected ? Theme.selected : (cellMouse.containsMouse ? Theme.rowHover : "transparent")

                // Barre d'accentuation verte 3px en bas pour la sélection en grille
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 3
                    color: Theme.accent
                    visible: cellItem.isSelected
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 8

                    FileIcon {
                        fileName: modelData.fileName
                        isDir: modelData.fileIsDir
                        size: 56
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        visible: !cellItem.isRenamingThis
                        text: modelData.fileName
                        color: cellItem.isSelected ? "#ffffff" : Theme.muted
                        font.pixelSize: 13
                        font.family: Theme.fontFamily
                        horizontalAlignment: Text.AlignHCenter
                        Layout.fillWidth: true
                        Layout.preferredWidth: 118
                        Layout.maximumWidth: 118
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        wrapMode: Text.NoWrap
                    }

                    Rectangle {
                        visible: cellItem.isRenamingThis
                        Layout.fillWidth: true
                        Layout.preferredWidth: 118
                        Layout.maximumWidth: 118
                        Layout.preferredHeight: 24
                        Layout.alignment: Qt.AlignHCenter
                        color: "#000000"
                        border.width: 1
                        border.color: Theme.accent
                        radius: 0

                        TextInput {
                            id: gridInlineInput
                            anchors.fill: parent
                            anchors.leftMargin: 4
                            anchors.rightMargin: 4
                            horizontalAlignment: TextInput.AlignHCenter
                            verticalAlignment: TextInput.AlignVCenter
                            color: "#ffffff"
                            font.pixelSize: 12
                            font.family: Theme.fontFamily
                            selectByMouse: true
                            clip: true
                            text: root.renameValue

                            focus: true
                            Component.onCompleted: if (visible) setupFocus()
                            onVisibleChanged: if (visible) setupFocus()
                            function setupFocus() {
                                gridInlineInput.text = root.renameValue;
                                Qt.callLater(function() {
                                    gridInlineInput.forceActiveFocus();
                                    var dot = gridInlineInput.text.lastIndexOf(".");
                                    if (!modelData.fileIsDir && dot > 0) {
                                        gridInlineInput.select(0, dot);
                                    } else {
                                        gridInlineInput.selectAll();
                                    }
                                });
                            }
                            Keys.onReturnPressed: (event) => { root.renameCommitted(text); event.accepted = true; }
                            Keys.onEnterPressed: (event) => { root.renameCommitted(text); event.accepted = true; }
                            Keys.onEscapePressed: (event) => { root.renameCancelled(); event.accepted = true; }
                        }
                    }
                }

                Component.onCompleted: {
                    if (index === 0 && root.selectedIndex === -1) {
                        root.selectedIndex = 0;
                        root.selectionChanged(0, {
                            name: modelData.fileName,
                            path: modelData.filePath,
                            isDir: modelData.fileIsDir,
                            size: root.formatSize(modelData.fileSize, modelData.fileIsDir),
                            modified: root.formatModified(modelData.fileModified),
                            type: root.formatType(modelData.fileName, modelData.fileIsDir)
                        });
                    }
                }

                MouseArea {
                    id: cellMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !cellItem.isRenamingThis
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onPressed: (mouse) => {
                        root.forceActiveFocus();
                        if (mouse.button === Qt.RightButton) {
                            var info = {
                                name: modelData.fileName,
                                path: modelData.filePath,
                                isDir: modelData.fileIsDir,
                                size: root.formatSize(modelData.fileSize, modelData.fileIsDir),
                                modified: root.formatModified(modelData.fileModified),
                                type: root.formatType(modelData.fileName, modelData.fileIsDir)
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
                                name: modelData.fileName,
                                path: modelData.filePath,
                                isDir: modelData.fileIsDir,
                                size: root.formatSize(modelData.fileSize, modelData.fileIsDir),
                                modified: root.formatModified(modelData.fileModified),
                                type: root.formatType(modelData.fileName, modelData.fileIsDir)
                            };
                            root.selectedIndex = index;
                            root.selectionChanged(index, info);
                        }
                    }

                    onDoubleClicked: (mouse) => {
                        if (mouse.button === Qt.LeftButton) {
                            root.fileActivated(index, modelData.filePath, modelData.fileIsDir);
                        }
                    }
                }
            }
        }
    }

    // Indexed against root.rows, not root.model: those are two different
    // sequences the moment a search is active, and the delegate indices follow
    // the rows.
    function getItem(idx: int) {
        if (idx < 0 || idx >= rows.length) return null;
        const r = rows[idx];
        return {
            name: r.fileName,
            path: r.filePath,
            isDir: r.fileIsDir,
            size: formatSize(r.fileSize, r.fileIsDir),
            modified: formatModified(r.fileModified),
            type: formatType(r.fileName, r.fileIsDir)
        };
    }

    function selectIndex(idx: int): void {
        if (idx < 0 || idx >= rows.length) return;
        selectedIndex = idx;
        const item = getItem(idx);
        if (item) {
            selectionChanged(idx, item);
        }
        gridView.positionViewAtIndex(idx, GridView.Contain);
    }

    function selectFirst(): void {
        if (rows.length > 0) {
            selectIndex(0);
        }
    }

    function handleRightClick(gx: real, gy: real): bool {
        var pt = gridView.mapFromItem(null, gx, gy);
        if (pt.x >= 0 && pt.x <= gridView.width && pt.y >= 0 && pt.y <= gridView.height) {
            var cx = pt.x + gridView.contentX;
            var cy = pt.y + gridView.contentY;
            var idx = gridView.indexAt(cx, cy);
            if (idx >= 0) {
                var item = root.getItem(idx);
                // No second filter here: root.rows is already filtered, and
                // getItem() indexes it, so re-testing the name only ever
                // disagreed with what the grid actually showed.
                if (item) {
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
