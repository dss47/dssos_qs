pragma Singleton
import QtQuick

// Single source of truth for every right-click menu in the OS.
// Callers only build a list, they never build UI:
//   ContextMenuState.show(x, 56, [
//       { label: "Copy", icon: "copy", hint: "C", action: function() { doThing(); } },
//       { sep: true },
//       { label: "Clear value", danger: true, action: function() { doOther(); } },
//   ], "App name")
// Item shape: { label, action, icon?: assets/icons name, hint?: shortcut text,
//               danger?: bool, enabled?: bool (false greys the row), sep?: bool }
QtObject {
    id: root

    property bool open: false
    property string title: ""
    property real cursorX: 0
    property real topMargin: 0
    property real bottomMargin: Style.flyoutBottom
    property bool openAbove: false
    property var desktopMenuCallback: null

    // rowsModel carries plain data roles only; actions stay in a JS array
    // and are dispatched by index from fire(), never bound to the view.
    property ListModel rowsModel: ListModel {}
    property var actions: []

    function showAt(x, y, model, screenHeight) {
        var sh = (screenHeight && screenHeight > 0) ? screenHeight : ((Quickshell.screens && Quickshell.screens.length > 0) ? Quickshell.screens[0].height : 768);
        root.cursorX = x;
        if (y < sh / 2) {
            // Curseur dans la moitié supérieure : ouvre EN-DESSOUS du curseur
            root.openAbove = false;
            root.topMargin = Math.round(y);
            root.bottomMargin = 0;
        } else {
            // Curseur dans la moitié inférieure : ouvre AU-DESSUS du curseur
            root.openAbove = true;
            root.topMargin = 0;
            root.bottomMargin = Math.round(sh - y);
        }
        root._populate(model, "");
    }

    function show(x, bottom, model, name) {
        root.cursorX = x;
        root.openAbove = true;
        root.topMargin = 0;
        root.bottomMargin = Math.round(bottom);
        root._populate(model, name);
    }

    function _populate(model, name) {
        title = (name === undefined || name === null) ? "" : name;
        rowsModel.clear();
        const acts = [];
        const list = (model === undefined || model === null) ? [] : model;
        for (var i = 0; i < list.length; i++) {
            const r = list[i];
            if (!r) { continue; }
            const isSep = r.sep === true;
            const lbl = isSep ? "" : ((r.label === undefined || r.label === null) ? "" : r.label);
            const hn = (r.hint === undefined || r.hint === null) ? "" : r.hint;
            rowsModel.append({
                "label": lbl,
                "hint": hn,
                "danger": r.danger === true,
                "ison": r.enabled !== false,
                "kind": isSep ? "sep" : "row"
            });
            if (typeof r.action === "function") { acts.push(r.action); } else { acts.push(null); }
        }
        actions = acts;
        open = true;
    }
    function fire(i) {
        const a = (i >= 0 && i < actions.length) ? actions[i] : null;
        open = false;
        if (a) { a(); }
    }
    function hide() {
        open = false;
    }
}
