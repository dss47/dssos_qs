//@ pragma IconTheme Papirus-Dark
//@ pragma UseQApplication
import QtQuick
import QtQuick.Layouts
import QtQuick.Window

import Quickshell
import Quickshell.Io
import Qt.labs.folderlistmodel
import "components"
import common

Window {
    id: win
    title: "Files"
    visible: true
    onClosing: if (standalone) Qt.quit()
    minimumWidth: 800
    minimumHeight: 520
    width: 1000
    height: 560
    color: Theme.bg

    property bool standalone: true
    property bool csd: false
    flags: Qt.Window | (csd ? Qt.FramelessWindowHint : 0)

    // État de navigation
    property string currentPath: Paths.downloads
    property var history: [Paths.downloads]
    property int historyIndex: 0
    // List view is the default: it shows size and modified date inline, which
    // is what you actually want when hunting for a file. Grid is one keypress away.
    property bool isGrid: false
    // The details pane is opt-in: it costs a third of the window, so it starts
    // closed and Ctrl+P / the (i) button opens it.
    property bool showPreview: false

    // Sorting. FolderListModel does the work; these are just the choices.
    property string sortField: "Name"
    property bool sortAscending: true

    // Inline rename editor
    property bool renaming: false
    property string renameValue: ""

    // Transient message shown in the status area.
    property string toast: ""
    property bool toastIsError: false

    property var selectedItem: null
    property int selectedIndex: -1

    // Wayfire repaint workaround.
    //
    // Toggling the content column's opacity is what forces the whole window
    // through a fresh render pass, which is how the stale-area bug under
    // Wayfire was worked around.
    //
    // The old form was `opacity: (repaintTick % 2 === 0) ? 1.0 : 0.999`, which
    // has a defect the audit did not mention: after any odd number of resizes
    // the window stayed at 0.999 for the rest of the session, keeping a
    // full-window offscreen buffer alive forever for nothing. It is a pulse
    // now -- off to 0.999, then explicitly back to a clean 1.0.
    property int repaintTick: 0
    property bool repaintPulse: false
    property bool uiReady: false
    Component.onCompleted: {
        uiReady = true;
        // Create ~/Desktop, ~/Videos, ... if they are missing, then let the
        // sidebar rebuild once every place points at its own directory.
        Paths.ensureStandardDirs();
    }

    onWidthChanged: if (uiReady) repaintDebounce.restart()
    onHeightChanged: if (uiReady) repaintDebounce.restart()

    Timer {
        id: repaintDebounce
        interval: 300
        repeat: false
        onTriggered: {
            win.repaintTick++;
            win.repaintPulse = true;
            repaintRestore.restart();
        }
    }

    // One frame at 0.999 is enough to trigger the redraw; after that the
    // window goes back to exactly 1.0 and stops costing an offscreen pass.
    Timer {
        id: repaintRestore
        interval: 60
        repeat: false
        onTriggered: win.repaintPulse = false
    }

    FolderListModel {
        id: folderModel
        folder: "file://" + win.currentPath
        showDirsFirst: true
        showHidden: false
        showDotAndDotDot: false

        // FolderListModel only accepts its enum values, so map from the plain
        // names the column headers use. Keeping the strings here means the UI never
        // has to know the enum numbers.
        sortField: {
            switch (win.sortField) {
            case "Size": return FolderListModel.Size;
            case "Date": return FolderListModel.Time;   // Qt calls it "Time"
            case "Type": return FolderListModel.Type;
            default:    return FolderListModel.Name;
            }
        }
        // Qt 6 models direction as a boolean, not a sortOrder enum.
        sortReversed: !win.sortAscending

        onStatusChanged: {
            if (status === FolderListModel.Ready) {
                if (win.pendingCreatedFolderToRename !== "") {
                    const target = win.pendingCreatedFolderToRename;
                    const found = win.selectByName(target, true);
                    if (found) {
                        win.pendingCreatedFolderToRename = "";
                        return;
                    }
                }
                if (win.selectedItem && win.selectedItem.name) {
                    const foundSelected = win.selectByName(win.selectedItem.name, false);
                    if (foundSelected) return;
                }
                if (folderModel.count > 0) {
                    if (win.isGrid) fileGridView.selectFirst();
                    else fileListView.selectFirst();
                } else {
                    win.selectedIndex = -1;
                    win.selectedItem = null;
                }
            }
        }
    }

    function selectByName(name: string, startRename: bool): bool {
        if (!folderModel) return false;
        for (var i = 0; i < folderModel.count; i++) {
            if (folderModel.get(i, "fileName") === name) {
                if (win.isGrid) fileGridView.selectIndex(i);
                else fileListView.selectIndex(i);
                if (startRename) {
                    win.renameValue = name;
                    win.renaming = true;
                }
                return true;
            }
        }
        return false;
    }

    function setSortField(f) {
        win.sortField = f;
    }

    function toggleSortOrder() {
        win.sortAscending = !win.sortAscending;
    }

    function notify(msg, isError) {
        win.toastIsError = isError === true;
        win.toast = "";
        win.toast = msg;
        toastTimer.restart();
    }

    Timer {
        id: toastTimer
        interval: 4000
        onTriggered: win.toast = ""
    }

    // ------------------------------------------------------- file operations

    // Clipboard, Undo & Trash state
    //
    // clipboardAction mirrors Paths.clipboardAction for the current window only.
    // The file list itself is not held here: it lives on the system clipboard,
    // so it survives a restart of this host and is shared with other apps.
    property string clipboardAction: ""
    property var undoStack: []
    property var lastTrashedItem: null
    property string pendingCreatedFolderToRename: ""
    property string pendingRenameOldPath: ""
    property string pendingRenameOldName: ""
    property string pendingRenameNewPath: ""
    readonly property bool isTrash: currentPath === Paths.trash || currentPath.startsWith(Paths.trash)

    FileOps {
        id: fileOps
        onFolderCreated: (path, name) => {
            win.pushUndo("Create folder " + name, function() {
                fileOps.trash(path);
            });
            const found = win.selectByName(name, true);
            if (!found) {
                win.pendingCreatedFolderToRename = name;
            }
        }
        onFinished: (op, ok, message, extra) => {
            if (op === "rename") {
                win.renaming = false;
                if (ok) {
                    win.notify("Renamed");
                    if (win.pendingRenameOldPath && win.pendingRenameNewPath) {
                        const oPath = win.pendingRenameOldPath;
                        const nPath = win.pendingRenameNewPath;
                        const oName = win.pendingRenameOldName;
                        win.pendingRenameOldPath = "";
                        win.pendingRenameNewPath = "";
                        win.pendingRenameOldName = "";
                        win.pushUndo("Rename " + oName, function() {
                            fileOps.rename(nPath, oName);
                        });
                    }
                } else if (!ok) {
                    win.notify(message, true);
                }
            } else if (op === "mkdir") {
                if (ok) win.notify("Folder created");
                else win.notify(message, true);
            } else if (op === "trash") {
                if (ok) {
                    const trashed = win.lastTrashedItem;
                    win.lastTrashedItem = null;
                    win.selectedItem = null;
                    win.selectedIndex = -1;
                    win.notify("Moved to Trash");
                    if (trashed) {
                        // Ctrl+A then Delete trashes N items, but the undo only
                        // ever called restoreTrash once, on trashed.path -- and
                        // path is srcs[0]. So "Delete 12 items" then Ctrl+Z
                        // brought back one file and lost eleven, silently.
                        // trashed.paths is the full list, and restoreTrash
                        // takes a list.
                        const all = (trashed.paths && trashed.paths.length > 0)
                                    ? trashed.paths.slice() : [trashed.path];
                        win.pushUndo("Delete " + trashed.name, function() {
                            fileOps.restoreTrash(all);
                        });
                    }
                } else {
                    win.notify(message, true);
                }
            } else if (op === "copy") {
                if (ok) {
                    const created = win.parseOpLines(extra, "COPIED:");
                    if (created.length > 0) {
                        win.notify(created.length === 1 ? "Pasted 1 item"
                                                        : "Pasted " + created.length + " items");
                        // Undo is one step for the whole batch: it is what the
                        // user just did, and a stack entry per file would make
                        // Ctrl+Z look like it needed pressing N times.
                        win.pushUndo("Paste " + created.length, function() {
                            for (let i = 0; i < created.length; ++i)
                                fileOps.trash(created[i]);
                        });
                    } else {
                        win.notify("Nothing pasted");
                    }
                } else {
                    win.notify(message, true);
                }
            } else if (op === "cut") {
                if (ok) {
                    const moved = win.parseOpLines(extra, "MOVED:");
                    win.notify(moved.length === 1 ? "Moved 1 item"
                                                  : "Moved " + moved.length + " items");
                    // Undo a move by moving back. The source folder is derivable
                    // from the destination only because the CLI echoes the path
                    // it created; for the common case that is the current folder
                    // this is exactly reversible.
                    if (moved.length > 0 && win._moveSourceDir !== "") {
                        const srcDir = win._moveSourceDir;
                        win.pushUndo("Move " + moved.length, function() {
                            fileOps.moveItems(moved, srcDir);
                        });
                    }
                    Paths.clipboardAction = "";
                } else {
                    win.notify(message, true);
                }
            } else if (op === "paste_text") {
                if (ok) {
                    win.notify("Created text file");
                    const created = win.parseOpLines(extra, "CREATED:");
                    if (created.length > 0) {
                        win.pushUndo("Paste text", function() {
                            fileOps.trash(created[0]);
                        });
                    }
                } else {
                    win.notify(message, true);
                }
            } else if (op === "restore") {
                if (ok) win.notify("Restored from Trash");
                else win.notify(message, true);
            } else if (op === "empty_trash") {
                if (ok) win.notify("Trash emptied");
                else win.notify(message, true);
            }
        }
    }

    property bool allSelected: false

    function selectAll() {
        if (folderModel.count > 0) {
            win.allSelected = true;
            win.selectedIndex = 0;
            if (win.isGrid) win.selectedItem = fileGridView.getItem(0);
            else win.selectedItem = fileListView.getItem(0);
            notify(folderModel.count + " items selected");
        }
    }

    // What the next Ctrl+C / Ctrl+X acts on: everything when Ctrl+A is active,
    // otherwise just the active row. Returns absolute paths because that is what
    // both the clipboard and the shell scripts take.
    function selectedPaths() {
        if (isTrash) return [];
        const out = [];
        if (allSelected) {
            for (let i = 0; i < folderModel.count; ++i) {
                const p = folderModel.get(i, "filePath") || "";
                if (p !== "") out.push(p);
            }
            return out;
        }
        if (selectedItem && selectedItem.path) out.push(selectedItem.path);
        return out;
    }

    function canPaste(): bool {
        // The clipboard now lives outside this process, so it cannot be
        // inspected without shelling out. Assume there is something and let
        // paste() report the empty case, which keeps Ctrl+V from being dead
        // when another application owns the clipboard.
        return !isTrash;
    }

    function cutSelection() {
        if (isTrash) return;
        const srcs = selectedPaths();
        if (srcs.length === 0) return;
        // Cut still publishes to the system clipboard: pasting into another
        // application must be able to move the file, which is what makes the
        // files deselect-looking-but-still-there state consistent.
        Paths.writeClipboard(srcs);
        Paths.clipboardAction = "cut";
        notify("Cut " + srcs.length + (srcs.length === 1 ? " item" : " items"));
    }

    function copySelection() {
        if (isTrash) return;
        const srcs = selectedPaths();
        if (srcs.length === 0) return;
        Paths.writeClipboard(srcs);
        Paths.clipboardAction = "copy";
        notify("Copied " + srcs.length + (srcs.length === 1 ? " item" : " items"));
    }

    function paste() {
        if (isTrash) return;
        Paths.readClipboard(function (kind, text) {
            if (kind === "" || text === "") {
                notify("Clipboard is empty", true);
                return;
            }

            if (kind === "uris") {
                const srcs = Paths.parseUriList(text);
                // Pasting a folder into itself would copy it inside itself
                // forever, so those are dropped with a word rather than
                // silently half-done.
                const usable = srcs.filter(function (p) { return p !== win.currentPath; });
                const skipped = srcs.length - usable.length;
                if (usable.length === 0) {
                    notify("Cannot paste a folder into itself", true);
                    return;
                }
                if (Paths.clipboardAction === "cut") {
                    // Remember where they came from before the move, while the
                    // information still exists.
                    win._moveSourceDir = Paths.dirname(usable[0]);
                    fileOps.moveItems(usable, win.currentPath);
                    // Cut is consumed: pasting twice must copy the second time,
                    // otherwise the second Ctrl+V reports everything is gone.
                    Paths.clipboardAction = "";
                } else {
                    fileOps.copyItems(usable, win.currentPath);
                }
                if (skipped > 0) notify("Skipped " + skipped + " (same folder)", true);
                return;
            }

            fileOps.pasteText(text, win.currentPath);
        });
    }

    // The CLI reports one "TAG:<path>" line per item it actually touched.
    // Only lines with the expected tag are kept, so a partial failure (some
    // files copied, one unreadable) still reports the ones that worked
    // instead of being discarded wholesale.
    function parseOpLines(text, tag) {
        const out = [];
        if (!text) return out;
        const lines = String(text).split("\n");
        for (let i = 0; i < lines.length; ++i) {
            const l = lines[i].trim();
            if (l.indexOf(tag) !== 0) continue;
            const p = l.substring(tag.length).trim();
            if (p !== "") out.push(p);
        }
        return out;
    }

    // Where the last batch of moves came from, so Ctrl+Z can put it back.
    property string _moveSourceDir: ""

    function pushUndo(desc, undoFn) {
        undoStack.push({ desc: desc, undo: undoFn });
    }

    function undo() {
        console.log("--> win.undo called, stack length:", undoStack.length);
        if (undoStack.length === 0) {
            notify("Nothing to undo");
            return;
        }
        const item = undoStack.pop();
        if (item && typeof item.undo === "function") {
            item.undo();
            notify("Undid: " + item.desc);
        }
    }

    function restoreSelectionFromTrash() {
        if (!selectedItem) return;
        fileOps.restoreTrash(selectedItem.path);
    }

    function emptyTrash() {
        fileOps.emptyTrash();
    }

    function beginRename() {
        if (!win.selectedItem) {
            win.notify("Select an item first", true);
            return;
        }
        win.renameValue = win.selectedItem.name;
        win.renaming = true;
    }

    function commitRename(newName) {
        if (!win.renaming || !win.selectedItem) return;
        var val = (newName !== undefined && newName !== null) ? newName : win.renameValue;
        val = val.trim();
        win.renaming = false;
        if (win.isGrid) fileGridView.forceActiveFocus();
        else fileListView.forceActiveFocus();
        if (val === "" || val === win.selectedItem.name) return;
        win.pendingRenameOldPath = win.selectedItem.path;
        win.pendingRenameOldName = win.selectedItem.name;
        const dir = win.selectedItem.path.substring(0, win.selectedItem.path.lastIndexOf("/"));
        win.pendingRenameNewPath = dir + "/" + val;
        fileOps.rename(win.selectedItem.path, val);
    }

    function cancelRename() {
        win.renaming = false;
        if (win.isGrid) fileGridView.forceActiveFocus();
        else fileListView.forceActiveFocus();
    }

    function newFolder() {
        fileOps.createFolder(win.currentPath, "New folder");
    }

    // Uses selectedPaths(), not win.selectedItem: after Ctrl+A the highlight
    // covers every row while selectedItem is only the active one, so Delete
    // used to remove all but one of the selected items.
    function moveSelectionToTrash() {
        if (isTrash) {
            win.notify("Items in Trash are removed permanently", true);
            return;
        }
        const srcs = win.selectedPaths();
        if (srcs.length === 0) {
            win.notify("Select an item first", true);
            return;
        }
        win.lastTrashedItem = {
            name: srcs.length === 1 ? srcs[0].split("/").pop() : srcs.length + " items",
            path: srcs[0],
            isDir: !win.selectedItem || win.selectedItem.isDir,
            paths: srcs.slice()
        };
        fileOps.trash(srcs);
    }

    // Shift+Delete: irreversible, so it always asks first.
    property bool confirmDelete: false

    property var pendingDeletePaths: []

    function requestPermanentDelete() {
        const srcs = win.selectedPaths();
        if (srcs.length === 0) {
            win.notify("Select an item first", true);
            return;
        }
        win.pendingDeletePaths = srcs;
        win.confirmDelete = true;
    }

    function confirmPermanentDelete() {
        win.confirmDelete = false;
        const srcs = win.pendingDeletePaths || [];
        win.pendingDeletePaths = [];
        if (srcs.length === 0) return;
        fileOps.permanentDelete(srcs, false);
    }

    function navigateTo(path: string): void {
        let clean = path.replace(/\/+$/, "");
        if (clean === "") clean = "/";
        if (clean === win.currentPath) return;

        if (win.historyIndex < win.history.length - 1) {
            win.history = win.history.slice(0, win.historyIndex + 1);
        }
        win.history = win.history.concat([clean]);
        win.historyIndex = win.history.length - 1;
        win.currentPath = clean;
        win.selectedIndex = -1;
        win.selectedItem = null;
    }

    function goBack(): void {
        if (win.historyIndex > 0) {
            win.historyIndex--;
            win.currentPath = win.history[win.historyIndex];
            win.selectedIndex = -1;
            win.selectedItem = null;
        }
    }

    function goForward(): void {
        if (win.historyIndex < win.history.length - 1) {
            win.historyIndex++;
            win.currentPath = win.history[win.historyIndex];
            win.selectedIndex = -1;
            win.selectedItem = null;
        }
    }

    function goUp(): void {
        if (win.currentPath === "/" || win.currentPath === "") return;
        let lastSlash = win.currentPath.lastIndexOf("/");
        let parentPath = lastSlash <= 0 ? "/" : win.currentPath.substring(0, lastSlash);
        win.navigateTo(parentPath);
    }

    function openFile(filePath: string): void {
        openProc.command = ["xdg-open", filePath];
        openProc.running = true;
    }

    Process {
        id: openProc
        command: []
        running: false
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        opacity: win.repaintPulse ? 0.999 : 1.0

        // 1. Barre d'outils supérieure (44px)
        Toolbar {
            id: toolbar
            Layout.fillWidth: true
            currentPath: win.currentPath
            canGoBack: win.historyIndex > 0
            canGoForward: win.historyIndex < win.history.length - 1
            canGoUp: win.currentPath !== "/"
            isGrid: win.isGrid
            onBackClicked: win.goBack()
            onForwardClicked: win.goForward()
            onUpClicked: win.goUp()
            onNavigateTo: path => win.navigateTo(path)
            onToggleView: grid => win.isGrid = grid
            onMenuClicked: win.showPreview = !win.showPreview
        }

        // 2. Corps principal (Sidebar | Main View | Preview)
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // Barre latérale (200px)
            Sidebar {
                id: sidebar
                Layout.preferredWidth: Theme.sidebarWidth
                Layout.fillHeight: true
                currentPath: win.currentPath
                onLocationSelected: path => win.navigateTo(path)
            }

            // Vue Principale (Liste ou Grille)
            // Sorting lives in the list's column headers (Windows style), so
            // there is no separate sort bar. Grid view has no headers and
            // inherits whatever sort the list last used.
            Item {
                id: mainArea
                Layout.fillWidth: true
                Layout.fillHeight: true

                        FileList {
                            id: fileListView
                            anchors.fill: parent
                            visible: !win.isGrid
                            model: folderModel
                            selectedIndex: win.selectedIndex
                            searchQuery: toolbar.searchQuery
                            sortField: win.sortField
                            sortAscending: win.sortAscending
                            onSortFieldSelected: (f) => win.setSortField(f)
                            onSortOrderToggled: win.toggleSortOrder()
                            onFileActivated: (index, path, isDir) => {
                                if (win.isTrash) {
                                    win.restoreSelectionFromTrash();
                                    return;
                                }
                                if (isDir) win.navigateTo(path);
                                else win.openFile(path);
                            }
                            allSelected: win.allSelected
                            onSelectionChanged: (index, info) => {
                                win.allSelected = false;
                                win.selectedIndex = index;
                                win.selectedItem = info;
                            }
                            isTrash: win.isTrash
                            renaming: win.renaming
                            renameValue: win.renameValue
                            onRenameCommitted: (n) => win.commitRename(n)
                            onRenameCancelled: () => win.cancelRename()
                            onSelectAllRequested: win.selectAll()
                            onCopyRequested: win.copySelection()
                            onCutRequested: win.cutSelection()
                            onPasteRequested: win.paste()
                            onUndoRequested: win.undo()
                            onGoUpRequested: win.goUp()
                            onGoBackRequested: win.goBack()
                            onGoForwardRequested: win.goForward()
                            onRenameRequested: win.beginRename()
                            onDeleteRequested: (perm) => { if (perm || win.isTrash) win.requestPermanentDelete(); else win.moveSelectionToTrash(); }
                            onNewFolderRequested: win.newFolder()
                            onContextMenuRequested: (gx, gy, info) => win.showItemContextMenu(gx, gy, info)
                            onEmptySpaceContextMenuRequested: (gx, gy) => win.showEmptyContextMenu(gx, gy)
                        }

                        FileGrid {
                            id: fileGridView
                            anchors.fill: parent
                            visible: win.isGrid
                            model: folderModel
                            selectedIndex: win.selectedIndex
                            allSelected: win.allSelected
                            onSelectionChanged: (index, info) => {
                                win.allSelected = false;
                                win.selectedIndex = index;
                                win.selectedItem = info;
                            }
                            searchQuery: toolbar.searchQuery
                            isTrash: win.isTrash
                            renaming: win.renaming
                            renameValue: win.renameValue
                            onRenameCommitted: (n) => win.commitRename(n)
                            onRenameCancelled: () => win.cancelRename()
                            onSelectAllRequested: win.selectAll()
                            onCopyRequested: win.copySelection()
                            onCutRequested: win.cutSelection()
                            onPasteRequested: win.paste()
                            onUndoRequested: win.undo()
                            onGoUpRequested: win.goUp()
                            onGoBackRequested: win.goBack()
                            onGoForwardRequested: win.goForward()
                            onRenameRequested: win.beginRename()
                            onDeleteRequested: (perm) => { if (perm || win.isTrash) win.requestPermanentDelete(); else win.moveSelectionToTrash(); }
                            onNewFolderRequested: win.newFolder()
                            onFileActivated: (index, path, isDir) => {
                                if (win.isTrash) {
                                    win.restoreSelectionFromTrash();
                                    return;
                                }
                                if (isDir) win.navigateTo(path);
                                else win.openFile(path);
                            }
                            onContextMenuRequested: (gx, gy, info) => win.showItemContextMenu(gx, gy, info)
                            onEmptySpaceContextMenuRequested: (gx, gy) => win.showEmptyContextMenu(gx, gy)
                        }

                        // Confirmation dialog for irreversible delete (Shift+Delete).
                        Rectangle {
                            anchors.fill: parent
                            color: "#99000000"
                            visible: win.confirmDelete

                            MouseArea {
                                anchors.fill: parent
                                onClicked: win.confirmDelete = false
                            }

                            Rectangle {
                                anchors.centerIn: parent
                                width: 420
                                height: 132
                                color: Theme.card
                                border.width: 1
                                border.color: Theme.danger

                                Text {
                                    id: delTitle
                                    anchors.left: parent.left
                                    anchors.leftMargin: 18
                                    anchors.top: parent.top
                                    anchors.topMargin: 16
                                    text: "Delete permanently?"
                                    color: Theme.text
                                    font.pixelSize: Theme.fontSizeTitle
                                    font.family: Theme.fontFamily
                                }

                                Text {
                                    anchors.left: delTitle.left
                                    anchors.right: parent.right
                                    anchors.rightMargin: 18
                                    anchors.top: delTitle.bottom
                                    anchors.topMargin: 6
                                    text: "This cannot be undone. Use plain Delete to move "
                                          + "items to Trash instead."
                                    color: Theme.muted
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.family: Theme.fontFamily
                                    wrapMode: Text.WordWrap
                                }

                                RowLayout {
                                    anchors.right: parent.right
                                    anchors.rightMargin: 18
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 16
                                    spacing: 10

                                    DssButton {
                                        text: "Cancel"
                                        variant: "ghost"
                                        onClicked: win.confirmDelete = false
                                    }
                                    DssButton {
                                        text: "Delete"
                                        variant: "danger"
                                        onClicked: win.confirmPermanentDelete()
                                    }
                                }
                            }
                        }
                    }

            // Volet d'aperçu droit (230px)
            Preview {
                id: previewPanel
                Layout.fillHeight: true
                visible: win.showPreview
                fileInfo: win.selectedItem
                currentPath: win.currentPath
                onOpenRequested: path => {
                    if (win.selectedItem && win.selectedItem.isDir) {
                        win.navigateTo(path);
                    } else {
                        win.openFile(path);
                    }
                }
            }
        }

        // 3. Barre d'état inférieure (26px)
        StatusBar {
            id: statusBar
            Layout.fillWidth: true
            itemCount: folderModel.count
            fileInfo: win.selectedItem
            toast: win.toast
            toastIsError: win.toastIsError
        }
    }
    // Raccourcis clavier, en Shortcut et non en Keys.onPressed.
    //
    // They used to hang off a sibling Item with focus: true. FileList and
    // FileGrid both declare focus: true and call forceActiveFocus() the moment
    // anything is clicked, so the sibling lost focus for good and Ctrl+L,
    // Ctrl+F, Ctrl+H, Ctrl+P, Ctrl+N, Ctrl+I, Ctrl+A, Ctrl+Z, F2, Delete and
    // Escape all died as soon as the user touched the list.
    //
    // Shortcut is resolved by the window rather than by the focused item.
    Shortcut { sequence: "Ctrl+L"; onActivated: toolbar.focusPathInput() }
    Shortcut { sequence: "Ctrl+F"; onActivated: toolbar.focusSearch() }
    Shortcut { sequence: "Ctrl+H"; onActivated: folderModel.showHidden = !folderModel.showHidden }
    Shortcut { sequence: "Ctrl+P"; onActivated: win.showPreview = !win.showPreview }
    Shortcut { sequence: "Ctrl+N"; onActivated: win.newFolder() }
    Shortcut { sequence: "Ctrl+I"; onActivated: win.isGrid = !win.isGrid }
    Shortcut { sequence: "Ctrl+X"; onActivated: win.cutSelection() }
    Shortcut { sequence: "Ctrl+C"; onActivated: win.copySelection() }
    Shortcut { sequence: "Ctrl+V"; onActivated: win.paste() }
    Shortcut { sequence: "Ctrl+A"; onActivated: win.selectAll() }
    Shortcut { sequence: "Ctrl+Z"; onActivated: win.undo() }

    Shortcut { sequence: "Alt+Left";  onActivated: win.goBack() }
    Shortcut { sequence: "Alt+Right"; onActivated: win.goForward() }
    Shortcut { sequence: "Backspace"; onActivated: win.goUp() }
    Shortcut { sequence: "F2"; onActivated: if (!win.isTrash) win.beginRename() }
    Shortcut { sequence: "Menu";     onActivated: win.openContextMenuShortcut() }
    Shortcut { sequence: "Shift+F10"; onActivated: win.openContextMenuShortcut() }

    Shortcut {
        sequence: "Delete"
        onActivated: {
            if (win.confirmDelete) { win.confirmPermanentDelete(); return; }
            if (win.isTrash) win.requestPermanentDelete();
            else win.moveSelectionToTrash();
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: {
            if (win.renaming) win.cancelRename();
            else if (win.confirmDelete) win.confirmDelete = false;
        }
    }

    Shortcut {
        sequence: "Return"
        onActivated: {
            if (win.confirmDelete) win.confirmPermanentDelete();
            else if (win.isTrash && win.selectedItem) win.restoreSelectionFromTrash();
        }
    }
    Shortcut {
        sequence: "Enter"
        onActivated: {
            if (win.confirmDelete) win.confirmPermanentDelete();
            else if (win.isTrash && win.selectedItem) win.restoreSelectionFromTrash();
        }
    }

    // Shared by Menu and Shift+F10 so both keys do exactly the same thing.
    function openContextMenuShortcut() {
        if (win.selectedItem) win.showItemContextMenu(320, 180, win.selectedItem);
        else win.showEmptyContextMenu(320, 180);
    }

    function showItemContextMenu(gx, gy, info) {
        if (!info) return;

        if (win.isTrash) {
            ctxMenu.popup(gx, gy, [
                {
                    label: "Restore",
                    shortcut: "Enter",
                    action: function() {
                        win.restoreSelectionFromTrash();
                    }
                },
                { separator: true },
                {
                    label: "Delete permanently",
                    shortcut: "Del",
                    action: function() {
                        win.requestPermanentDelete();
                    }
                },
                { separator: true },
                {
                    label: "Properties",
                    enabled: !win.showPreview,
                    action: function() {
                        win.showPreview = true;
                    }
                }
            ]);
            return;
        }

        ctxMenu.popup(gx, gy, [
            {
                label: "Open",
                shortcut: "Enter",
                action: function() {
                    if (info.isDir) win.navigateTo(info.path);
                    else win.openFile(info.path);
                }
            },
            { separator: true },
            {
                label: "Cut",
                shortcut: "Ctrl+X",
                action: function() {
                    win.cutSelection();
                }
            },
            {
                label: "Copy",
                shortcut: "Ctrl+C",
                action: function() {
                    win.copySelection();
                }
            },
            {
                label: "Paste",
                shortcut: "Ctrl+V",
                enabled: win.canPaste(),
                action: function() {
                    win.paste();
                }
            },
            { separator: true },
            {
                label: "Rename",
                shortcut: "F2",
                action: function() {
                    win.beginRename();
                }
            },
            {
                label: "Delete",
                shortcut: "Del",
                action: function() {
                    win.moveSelectionToTrash();
                }
            },
            { separator: true },
            {
                label: "Open in terminal",
                action: function() {
                    var targetDir = info.isDir ? info.path : info.path.substring(0, info.path.lastIndexOf("/"));
                    Quickshell.execDetached(["foot", "--working-directory=" + targetDir]);
                }
            },
            {
                label: "Properties",
                enabled: !win.showPreview,
                action: function() {
                    win.showPreview = true;
                }
            }
        ]);
    }

    function showEmptyContextMenu(gx, gy) {
        if (win.isTrash) {
            ctxMenu.popup(gx, gy, [
                {
                    label: "Empty Trash",
                    action: function() {
                        win.emptyTrash();
                    }
                }
            ]);
            return;
        }

        ctxMenu.popup(gx, gy, [
            {
                label: "New folder",
                shortcut: "Ctrl+N",
                action: function() {
                    win.newFolder();
                }
            },
            {
                label: "Paste",
                shortcut: "Ctrl+V",
                enabled: win.canPaste(),
                action: function() {
                    win.paste();
                }
            },
            { separator: true },
            {
                label: win.isGrid ? "List view" : "Grid view",
                action: function() {
                    win.isGrid = !win.isGrid;
                }
            },
            { separator: true },
            {
                label: "Open in terminal",
                action: function() {
                    Quickshell.execDetached(["foot", "--working-directory=" + win.currentPath]);
                }
            },
            {
                label: "Properties",
                enabled: !win.showPreview,
                action: function() {
                    win.showPreview = true;
                }
            }
        ]);
    }

    function handleOutsideRightClick(gx, gy) {
        if (!win.isGrid) {
            fileListView.handleRightClick(gx, gy);
        } else {
            fileGridView.handleRightClick(gx, gy);
        }
    }

    function dismissContextMenu() {
        ctxMenu.dismissImmediate();
    }

    onActiveChanged: {
        if (!win.active) {
            ctxMenu.dismissImmediate();
        }
    }

    DssContextMenu {
        id: ctxMenu
        onRightClickedOutside: (gx, gy) => win.handleOutsideRightClick(gx, gy)
    }
}
