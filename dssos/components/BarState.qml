pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property bool quickOpen: false
    property bool startOpen: false
    property bool hiddenOpen: false
    property string quickTarget: ""
    property string controlSubView: ""

    // only one flyout at a time
    onQuickOpenChanged: {
        if (quickOpen) {
            startOpen = false;
            hiddenOpen = false;
            if (quickTarget === "") quickTarget = "status";
        } else {
            quickTarget = "";
            controlSubView = "";
        }
    }
    onStartOpenChanged:  if (startOpen)  { quickOpen = false; hiddenOpen = false; quickTarget = ""; controlSubView = ""; }
    onHiddenOpenChanged: if (hiddenOpen) { quickOpen = false; startOpen = false; quickTarget = ""; controlSubView = ""; }

    // chevron x (window coords) for anchoring the hidden-tray popup
    property real hiddenX: 0

    // ----------------------------------------------------------------- Pinned Applications
    property var pinnedIds: ["dssos-files", "foot", "dssos-tasks", "dssos-settings"]

    function isPinned(appId) {
        if (!appId) return false;
        const target = appId.toString().toLowerCase().replace(/\.desktop$/, "");
        for (let i = 0; i < pinnedIds.length; i++) {
            const p = pinnedIds[i].toString().toLowerCase().replace(/\.desktop$/, "");
            if (p === target) return true;
        }
        return false;
    }

    function pinApp(appId) {
        if (!appId || isPinned(appId)) return;
        const clean = appId.toString().replace(/\.desktop$/, "");
        const next = [...pinnedIds, clean];
        pinnedIds = next;
        savePinned();
    }

    function unpinApp(appId) {
        if (!appId) return;
        const target = appId.toString().toLowerCase().replace(/\.desktop$/, "");
        const next = [];
        for (let i = 0; i < pinnedIds.length; i++) {
            const p = pinnedIds[i].toString().toLowerCase().replace(/\.desktop$/, "");
            if (p !== target) next.push(pinnedIds[i]);
        }
        pinnedIds = next;
        savePinned();
    }

    function togglePin(appId) {
        if (isPinned(appId)) unpinApp(appId);
        else pinApp(appId);
    }

    function savePinned() {
        Quickshell.execDetached([
            "sh", "-c",
            "mkdir -p ~/.config/dssos && echo '" + JSON.stringify(pinnedIds) + "' > ~/.config/dssos/pinned.json"
        ]);
    }

    property Process loadPinnedProc: Process {
        id: loadPinned
        command: ["sh", "-c", "cat ~/.config/dssos/pinned.json 2>/dev/null || echo ''"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const txt = text.trim();
                    if (txt && txt.length > 2) {
                        const data = JSON.parse(txt);
                        if (Array.isArray(data) && data.length > 0) {
                            root.pinnedIds = data;
                        }
                    }
                } catch(e) {}
            }
        }
    }

    Component.onCompleted: {
        loadPinnedProc.running = true;
    }
}
