//@ pragma IconTheme Papirus-Dark
//@ pragma UseQApplication
import QtQuick
import QtQuick.Layouts
import QtQuick.Window

import Quickshell
import Quickshell.Io
import "components"
import common

Window {
    id: win
    title: "Tasks"
    visible: true
    onClosing: if (standalone) Qt.quit()
    minimumWidth: 620
    minimumHeight: 480
    width: 700
    height: 580
    color: Theme.bg

    property bool standalone: true
    property bool csd: false
    flags: Qt.Window | (csd ? Qt.FramelessWindowHint : 0)

    // View state: 'ov' (Overview) or 'ps' (Processes)
    property string currentView: "ov"
    property int activeSort: 0 // 0: CPU, 1: Mem, 2: Disk, 3: Net
    property int filterType: 0 // 0: All, 1: Apps, 2: Background
    property string searchQuery: ""

    // Sparklines historical points (up to 40 samples)
    property var cpuHistory: [20, 22, 25, 24, 28, 30, 26, 22, 25, 23]
    property var memHistory: [50, 50, 51, 51, 52, 52, 52, 53, 53, 53]
    property var diskHistory: [4, 8, 2, 12, 15, 6, 2, 0, 5, 2]
    property var netHistory: [1, 5, 10, 2, 0, 1, 4, 12, 3, 1]

    // Sidebar current values
    property string cpuValue: "0%"
    property string cpuSubtitle: "Cores"
    property string memValue: "0 GB"
    property string memSubtitle: ""
    property string diskValue: "0 MB/s"
    property string diskSubtitle: ""
    property string netValue: "0 Mbps"
    property string netSubtitle: ""

    // Status bar & overview data
    property int processCount: 0
    property string uptimeText: "Uptime 0:00:00"
    property var rawProcesses: []

    // Repaint debounce for Wayfire resizing
    property int repaintTick: 0
    property bool uiReady: false
    Component.onCompleted: {
        uiReady = true;
        // callLater, like every other hand-started Process: assigning .running
        // in the same tick as .command is evaluated starts the child before the
        // command list is resolved, and the process comes up empty.
        Qt.callLater(function() {
            overviewProc.running = true;
            snapshotProc.running = true;
        });
    }
    onWidthChanged: if (uiReady) repaintDebounce.restart()
    onHeightChanged: if (uiReady) repaintDebounce.restart()

    Timer {
        id: repaintDebounce
        interval: 300
        repeat: false
        onTriggered: win.repaintTick++
    }

    // Periodic telemetry timer (1.2s interval)
    Timer {
        id: telemetryTimer
        interval: 1200
        repeat: true
        running: win.visible
        onTriggered: {
            if (!snapshotProc.running) {
                snapshotProc.running = true;
            }
        }
    }

    // Helper: Push value to history buffer (max 40 items)
    function pushHistory(arr, val) {
        var copy = arr.slice();
        if (copy.length >= 40) copy.shift();
        copy.push(val);
        return copy;
    }

    // 1. Overview fetch process
    property var overviewProc: Process {
        id: overviewProc
        command: ["dssos-tasks-ctl", "overview"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(text.trim());
                    overviewPage.deviceName = data.deviceName || "dss-pc";
                    overviewPage.processor = data.processor || "Unknown CPU";
                    overviewPage.installedRam = data.installedRam || "Unknown RAM";
                    overviewPage.graphics = data.graphics || "Unknown Graphics";
                    overviewPage.storage = data.storage || "Storage";
                    overviewPage.displayInfo = data.display || "1920 × 1080, 60 Hz";
                    overviewPage.systemType = data.systemType || "64-bit operating system, x86_64";
                    overviewPage.kernel = data.kernel || "Linux";
                    overviewPage.installedOn = data.installedOn || "16.10.2026";
                } catch (e) {}
            }
        }
    }

    // 2. Periodic Snapshot fetch process
    property var snapshotProc: Process {
        id: snapshotProc
        command: ["dssos-tasks-ctl", "snapshot"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var snap = JSON.parse(text.trim());
                    win.cpuValue = snap.cpu.toFixed(1) + "%";
                    win.cpuSubtitle = snap.cpuSubtitle || "";
                    win.cpuHistory = win.pushHistory(win.cpuHistory, snap.cpu);

                    win.memValue = snap.mem;
                    win.memSubtitle = snap.memSubtitle || "";
                    win.memHistory = win.pushHistory(win.memHistory, snap.memPercent || 50);

                    win.diskValue = snap.disk;
                    win.diskSubtitle = snap.diskSubtitle || "";
                    win.diskHistory = win.pushHistory(win.diskHistory, snap.diskPercent || 0);

                    win.netValue = snap.net;
                    win.netSubtitle = snap.netSubtitle || "";
                    win.netHistory = win.pushHistory(win.netHistory, snap.netPercent || 0);

                    win.uptimeText = snap.uptime || "Uptime 0:00:00";
                    win.processCount = snap.processCount || 0;
                    win.rawProcesses = snap.processes || [];
                } catch (e) {}
            }
        }
    }

    // 3. Process actions
    function killTarget(pid, force) {
        var action = force ? "kill" : "end";
        var cmd = ["dssos-tasks-ctl", action, "" + pid];
        actionProc.command = cmd;
        // Deferred: a Process started in the same tick as its `command`
        // assignment runs the PREVIOUS command.
        Qt.callLater(function () { actionProc.running = true; });
        // Schedule quick snapshot update
        quickRefreshTimer.restart();
    }

    property var actionProc: Process {
        id: actionProc
    }

    Timer {
        id: quickRefreshTimer
        interval: 350
        repeat: false
        onTriggered: {
            if (!snapshotProc.running) snapshotProc.running = true;
        }
    }

    // Keyboard Shortcuts (Standard + French layout)
    //
    // Converted from Keys.onPressed on a focus: true sibling to Shortcut.
    // ProcessList declares focus: true and calls forceActiveFocus() on click,
    // so the sibling lost focus for good and 1-4, Ctrl+F, Menu and Shift+F10
    // died as soon as the user selected a process. Shortcut is resolved by the
    // window, not by the focused item.
    Shortcut { sequence: "1"; onActivated: { win.currentView = "ps"; win.activeSort = 0; } }
    Shortcut { sequence: "2"; onActivated: { win.currentView = "ps"; win.activeSort = 1; } }
    Shortcut { sequence: "3"; onActivated: { win.currentView = "ps"; win.activeSort = 2; } }
    Shortcut { sequence: "4"; onActivated: { win.currentView = "ps"; win.activeSort = 3; } }

    Shortcut { sequence: "Ctrl+F"; onActivated: { win.currentView = "ps"; topBar.focusSearch(); } }

    Shortcut { sequence: "Menu";     onActivated: win.openContextMenuShortcut() }
    Shortcut { sequence: "Shift+F10"; onActivated: win.openContextMenuShortcut() }

    // Layout Root
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // 1. Top bar (Always visible, 52px)
        TopBar {
            id: topBar
            Layout.fillWidth: true
            currentView: win.currentView
            currentFilter: win.filterType
            searchText: win.searchQuery

            onOverviewClicked: {
                win.currentView = "ov";
            }
            onFilterChanged: function(flt) {
                win.filterType = flt;
            }
            onSearchChanged: function(txt) {
                win.searchQuery = txt;
            }
        }

        // 2. Body (Sidebar + Content Stack)
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // Sidebar (156px)
            Sidebar {
                Layout.preferredWidth: Theme.sidebarWidth
                Layout.fillHeight: true
                currentView: win.currentView
                activeSort: win.activeSort

                cpuValue: win.cpuValue
                cpuSubtitle: win.cpuSubtitle
                cpuHistory: win.cpuHistory

                memValue: win.memValue
                memSubtitle: win.memSubtitle
                memHistory: win.memHistory

                diskValue: win.diskValue
                diskSubtitle: win.diskSubtitle
                diskHistory: win.diskHistory

                netValue: win.netValue
                netSubtitle: win.netSubtitle
                netHistory: win.netHistory

                onSelectSort: function(idx) {
                    win.currentView = "ps";
                    win.activeSort = idx;
                }
            }

            // Content Stack
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // Overview Page
                OverviewPage {
                    id: overviewPage
                    anchors.fill: parent
                    visible: win.currentView === "ov"

                    onCopySpecs: {
                        var text = "Device name:\t" + overviewPage.deviceName + "\n"
                            + "Processor:\t" + overviewPage.processor + "\n"
                            + "Installed RAM:\t" + overviewPage.installedRam + "\n"
                            + "Graphics:\t" + overviewPage.graphics + "\n"
                            + "Storage:\t" + overviewPage.storage + "\n"
                            + "Display:\t" + overviewPage.displayInfo + "\n"
                            + "System type:\t" + overviewPage.systemType + "\n"
                            + "Kernel:\t\t" + overviewPage.kernel + "\n\n"
                            + "Edition:\t" + "DssOS\n"
                            + "Version:\t" + "1.0\n"
                            + "Compositor:\tWayfire\n"
                            + "Shell:\t\tQuickshell\n";
                        clipboardProc.command = ["wl-copy", text];
                        // Deferred: a Process started in the same tick as its
                        // `command` assignment runs the PREVIOUS command.
                        Qt.callLater(function () { clipboardProc.running = true; });
                    }
                }

                // Process List
                ProcessList {
                    id: processList
                    anchors.fill: parent
                    visible: win.currentView === "ps"
                    rawProcesses: win.rawProcesses
                    activeSort: win.activeSort
                    filterType: win.filterType
                    searchQuery: win.searchQuery

                    onEndTask: function(pid) { win.killTarget(pid, false); }
                    onForceQuit: function(pid) { win.killTarget(pid, true); }
                    onOpenLocation: function(path, pid) {
                        if (path && path.length > 0) {
                            var dir = path.substring(0, path.lastIndexOf("/"));
                            if (dir.length > 0) {
                                openLocProc.command = ["xdg-open", dir];
                                // Deferred: a Process started in the same tick as its
                                // `command` assignment runs the PREVIOUS command.
                                Qt.callLater(function () { openLocProc.running = true; });
                            }
                        }
                    }
                    onContextMenuRequested: function(gx, gy, proc) {
                        var hasExe = !!(proc && proc.exe && proc.exe.length > 0);
                        ctxMenu.popup(gx, gy, [
                            {
                                label: "End task",
                                icon: "process-stop",
                                shortcut: "Del",
                                action: function() { win.killTarget(proc.pid, false); }
                            },
                            {
                                label: "Kill",
                                icon: "window-close",
                                shortcut: "Shift+Del",
                                action: function() { win.killTarget(proc.pid, true); }
                            },
                            { separator: true },
                            {
                                label: "Copy PID",
                                icon: "edit-copy",
                                action: function() {
                                    clipboardProc.command = ["wl-copy", String(proc.pid)];
                                    // Deferred: a Process started in the same tick as its
                                    // `command` assignment runs the PREVIOUS command.
                                    Qt.callLater(function () { clipboardProc.running = true; });
                                }
                            },
                            {
                                label: "Copy name",
                                icon: "edit-copy",
                                action: function() {
                                    clipboardProc.command = ["wl-copy", proc.name || ""];
                                    // Deferred: a Process started in the same tick as its
                                    // `command` assignment runs the PREVIOUS command.
                                    Qt.callLater(function () { clipboardProc.running = true; });
                                }
                            },
                            { separator: true },
                            {
                                label: "Open location",
                                icon: "folder-open",
                                enabled: hasExe,
                                action: function() {
                                    if (hasExe) {
                                        var dir = proc.exe.substring(0, proc.exe.lastIndexOf("/"));
                                        if (dir.length > 0) {
                                            Quickshell.execDetached(["dssos-app", "files", dir]);
                                        }
                                    }
                                }
                            }
                        ]);
                    }
                }
            }
        }

        // 3. Status bar (28px)
        DssStatusBar {
            Layout.fillWidth: true
            leftText: win.processCount + " processes"
            middleText: win.uptimeText
            rightText: "Space: select · Del: end task"
        }
    }

    property var clipboardProc: Process { id: clipboardProc }
    property var openLocProc: Process { id: openLocProc }

    // Shared by Menu and Shift+F10 so both keys do exactly the same thing.
    function openContextMenuShortcut() {
        if (win.currentView !== "ps" || processList.selectedPid <= 0) return;
        var proc = null;
        for (var i = 0; i < win.rawProcesses.length; i++) {
            if (win.rawProcesses[i].pid === processList.selectedPid) {
                proc = win.rawProcesses[i];
                break;
            }
        }
        if (proc) processList.contextMenuRequested(300, 180, proc);
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
        onRightClickedOutside: (gx, gy) => processList.handleRightClick(gx, gy)
    }
}
