// DssOS apps host: ONE quickshell process for ALL user apps.
//
// System shell (qs -c dssos) stays untouched.
// Singleton apps (Settings, Tasks) are single Loaders (brought to front on repeat launch).
// Multi-instance apps (Files) are dynamically created Components on demand.
//
// Launchers: qs ipc -p <this file> call apps open <name>
//@ pragma IconTheme Papirus-Dark
//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import "./files"

ShellRoot {
    id: root

    // Known singleton apps
    readonly property var singletonApps: ["settings", "tasks"]
    property var openSingletons: []

    // Multi-instance tracker for Files
    property var filesInstances: []

    function dismissAllContextMenus(): void {
        for (var i = 0; i < filesInstances.length; i++) {
            if (filesInstances[i] && filesInstances[i].dismissContextMenu) {
                filesInstances[i].dismissContextMenu();
            }
        }
        if (tasksLoader.item && tasksLoader.item.dismissContextMenu) {
            tasksLoader.item.dismissContextMenu();
        }
    }

    IpcHandler {
        target: "context"
        function hide(): void {
            root.dismissAllContextMenus();
        }
    }

    Component {
        id: filesFactory
        Files {}
    }

    function openFilesWindow(targetPath: string): void {
        console.log("--> openFilesWindow called with:", targetPath, "current count:", filesInstances.length);
        var homeDir = Quickshell.env("HOME") || "/";
        var path = (targetPath && targetPath !== "") ? targetPath : homeDir;
        var count = filesInstances.length;
        var offset = (count * 36) % 200;

        var win = filesFactory.createObject(root, {
            standalone: false,
            currentPath: path,
            history: [path],
            historyIndex: 0,
            x: 60 + offset,
            y: 40 + offset
        });

        if (!win) {
            console.warn("Failed to instantiate Files window");
            return;
        }

        filesInstances.push(win);

        win.closing.connect(function(close) {
            close.accepted = true;
            var idx = filesInstances.indexOf(win);
            if (idx !== -1) {
                filesInstances.splice(idx, 1);
            }
            win.destroy();
        });

        win.visible = true;
        if (win.show) win.show();
        if (win.requestActivate) win.requestActivate();
    }

    function showSingleton(app: string): void {
        if (!singletonApps.includes(app))
            return;

        if (!openSingletons.includes(app)) {
            openSingletons = openSingletons.concat([app]);
        } else {
            // Already active: raise and bring to front
            if (app === "tasks" && tasksLoader.item) {
                tasksLoader.item.visible = true;
                if (tasksLoader.item.show) tasksLoader.item.show();
                if (tasksLoader.item.requestActivate) tasksLoader.item.requestActivate();
            } else if (app === "settings" && settingsLoader.item) {
                settingsLoader.item.visible = true;
                if (settingsLoader.item.show) settingsLoader.item.show();
                if (settingsLoader.item.requestActivate) settingsLoader.item.requestActivate();
            }
        }
    }

    function hideSingleton(app: string): void {
        if (!openSingletons.includes(app))
            return;
        openSingletons = openSingletons.filter(function (a) { return a !== app; });
    }

    IpcHandler {
        target: "apps"

        function open(app: string): void {
            if (app === "files") {
                root.openFilesWindow("");
            } else {
                root.showSingleton(app);
            }
        }

        function openPath(app: string, path: string): void {
            if (app === "files") {
                root.openFilesWindow(path);
            } else {
                root.showSingleton(app);
            }
        }

        function close(app: string): void {
            if (app === "files") {
                if (filesInstances.length > 0) {
                    var last = filesInstances.pop();
                    if (last) last.destroy();
                }
            } else {
                root.hideSingleton(app);
            }
        }
    }

    // --- settings (singleton) ------------------------------------------
    Loader {
        id: settingsLoader
        active: root.openSingletons.includes("settings")
        source: "./settings/Settings.qml"
        onLoaded: {
            item.standalone = false;
            item.visible = true;
            if (item.show) item.show();
            if (item.requestActivate) item.requestActivate();
        }
    }
    Connections {
        target: settingsLoader.item
        ignoreUnknownSignals: true
        function onClosing(close) {
            close.accepted = true;
            root.hideSingleton("settings");
        }
    }

    // --- tasks (singleton) ---------------------------------------------
    Loader {
        id: tasksLoader
        active: root.openSingletons.includes("tasks")
        source: "./tasks/Tasks.qml"
        onLoaded: {
            item.standalone = false;
            item.visible = true;
            if (item.show) item.show();
            if (item.requestActivate) item.requestActivate();
        }
    }
    Connections {
        target: tasksLoader.item
        ignoreUnknownSignals: true
        function onClosing(close) {
            close.accepted = true;
            root.hideSingleton("tasks");
        }
    }
}
