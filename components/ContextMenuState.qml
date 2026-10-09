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
    property bool open: false
    property string title: ""
    property real ax: 0
    property int marginBottom: 56

    // rowsModel carries plain data roles only; actions stay in a JS array
    // and are dispatched by index from fire(), never bound to the view.
    property ListModel rowsModel: ListModel {}
    property var actions: []

    function show(x, bottom, model, name) {
        ax = x;
        marginBottom = Math.round(bottom);
        if (name === undefined || name === null) { title = ""; } else { title = name; }
        rowsModel.clear();
        const acts = [];
        const list = (model === undefined || model === null) ? [] : model;
        for (var i = 0; i < list.length; i++) {
            const r = list[i];
            if (!r) { continue; }
            const isSep = r.sep === true;
            const lbl = isSep ? "" : ((r.label === undefined || r.label === null) ? "" : r.label);
            const ic = (r.icon === undefined || r.icon === null) ? "" : r.icon;
            const hn = (r.hint === undefined || r.hint === null) ? "" : r.hint;
            rowsModel.append({
                "label": lbl,
                "icon": ic,
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
