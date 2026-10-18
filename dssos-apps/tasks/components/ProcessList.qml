import QtQuick
import tasks
import common

Item {
    id: root

    property var rawProcesses: []
    property int activeSort: 0       // 0: CPU, 1: Mem, 2: Disk, 3: Net
    property int filterType: 0       // 0: All, 1: Apps, 2: Background
    property string searchQuery: ""
    property int selectedPid: -1

    signal endTask(int pid)
    signal forceQuit(int pid)
    signal openLocation(string path, int pid)
    signal contextMenuRequested(real gx, real gy, var proc)

    // Filtered & sorted process list
    readonly property var filteredProcesses: {
        var list = rawProcesses ? rawProcesses.slice() : [];
        var query = searchQuery.trim().toLowerCase();

        // 1. Filter by type & search
        list = list.filter(function(p) {
            if (filterType === 1 && !p.isApp) return false;
            if (filterType === 2 && p.isApp) return false;
            if (query.length > 0) {
                var matchName = p.name && p.name.toLowerCase().indexOf(query) !== -1;
                var matchPid = ("" + p.pid).indexOf(query) !== -1;
                if (!matchName && !matchPid) return false;
            }
            return true;
        });

        // 2. Sort descending
        list.sort(function(a, b) {
            if (activeSort === 0) return b.cpu - a.cpu;
            if (activeSort === 1) return b.mem - a.mem;
            if (activeSort === 2) return b.disk - a.disk;
            return b.net - a.net;
        });

        return list;
    }

    onFilteredProcessesChanged: {
        if (filteredProcesses.length > 0) {
            var exists = false;
            for (var i = 0; i < filteredProcesses.length; i++) {
                if (filteredProcesses[i].pid === selectedPid) {
                    exists = true;
                    break;
                }
            }
            if (!exists) {
                selectedPid = filteredProcesses[0].pid;
            }
        } else {
            selectedPid = -1;
        }
    }

    ListView {
        id: listView
        anchors.fill: parent
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: root.filteredProcesses

        focus: true

        Keys.onUpPressed: {
            selectOffset(-1);
        }
        Keys.onDownPressed: {
            selectOffset(1);
        }
        Keys.onDeletePressed: function(event) {
            if (root.selectedPid > 0) {
                if (event.modifiers & Qt.ShiftModifier) {
                    root.forceQuit(root.selectedPid);
                } else {
                    root.endTask(root.selectedPid);
                }
            }
        }

        delegate: ProcessRow {
            width: listView.width
            pid: modelData.pid
            name: modelData.name
            isApp: modelData.isApp
            iconColor: modelData.color || "#4da3ff"
            cpuVal: modelData.cpu || 0.0
            memVal: modelData.mem || 0.0
            diskVal: modelData.disk || 0.0
            netVal: modelData.net || 0.0
            threads: modelData.threads || 1
            exePath: modelData.exe || ""
            activeSort: root.activeSort
            isSelected: root.selectedPid === modelData.pid

            onRowClicked: {
                root.selectedPid = modelData.pid;
                listView.forceActiveFocus();
            }
            onEndTask: function(targetPid) { root.endTask(targetPid); }
            onForceQuit: function(targetPid) { root.forceQuit(targetPid); }
            onOpenLocation: function(path, targetPid) { root.openLocation(path, targetPid); }
            onContextMenuRequested: function(gx, gy) { root.contextMenuRequested(gx, gy, modelData); }
        }
    }

    function selectOffset(delta: int) {
        var list = root.filteredProcesses;
        if (!list || list.length === 0) return;
        var idx = -1;
        for (var i = 0; i < list.length; i++) {
            if (list[i].pid === root.selectedPid) {
                idx = i;
                break;
            }
        }
        var nextIdx = Math.max(0, Math.min(list.length - 1, idx + delta));
        root.selectedPid = list[nextIdx].pid;
        listView.positionViewAtIndex(nextIdx, ListView.Contain);
    }

    // Shared universal scrollbar
    DssScrollBar {
        target: listView
    }

    function handleRightClick(gx: real, gy: real): bool {
        var pt = listView.mapFromItem(null, gx, gy);
        if (pt.x >= 0 && pt.x <= listView.width && pt.y >= 0 && pt.y <= listView.height) {
            var cx = pt.x + listView.contentX;
            var cy = pt.y + listView.contentY;
            var idx = listView.indexAt(cx, cy);
            var list = root.filteredProcesses;
            if (idx >= 0 && idx < list.length) {
                var proc = list[idx];
                root.selectedPid = proc.pid;
                root.contextMenuRequested(gx, gy, proc);
                return true;
            }
        }
        return false;
    }
}
