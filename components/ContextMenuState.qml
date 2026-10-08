pragma Singleton
import QtQuick

// Single source of truth for every right-click menu in the OS.
// Callers only build a list, they never build UI:
//   ContextMenuState.show(x, 56, [
//       { label: "Copy", icon: "copy", hint: "⌘C", action: () => doThing() },
//       { sep: true },
//       { label: "Clear value", danger: true, action: () => doOther() },
//   ], "App name")
// Item shape: { label, action, icon?: assets/icons name, hint?: shortcut text,
//               danger?: bool, enabled?: bool (false hides the row), sep?: bool }
// NOTE: the view only binds to the primitive splits below. Function-bearing
// objects must never be bound to view properties, only called from fire().
QtObject {
    property bool open: false
    property string title: ""
    property real ax: 0
    property int marginBottom: 56

    // primitive splits, rebuilt on every show()
    property var labels: []
    property var icons: []
    property var hints: []
    property var dangers: []
    property var enableds: []
    property var kinds: []     // "row" or "sep"
    property var actions: []   // functions, called only from fire()

    function show(x, bottom, model, name) {
        ax = x;
        marginBottom = Math.round(bottom);
        title = name ?? "";
        const m = (model ?? []).filter(r => r);
        // data first, lengths last: the view builds delegates off labels.length,
        // so nothing renders until every array is complete (no transient gaps)
        icons = m.map(r => r.icon ?? "");
        hints = m.map(r => r.hint ?? "");
        dangers = m.map(r => r.danger === true);
        enableds = m.map(r => r.enabled !== false);
        kinds = m.map(r => r.sep === true ? "sep" : "row");
        actions = m.map(r => (typeof r.action === "function") ? r.action : null);
        labels = m.map(r => r.sep === true ? "" : (r.label ?? ""));
        open = true;
    }
    function fire(i) {
        const a = (i >= 0 && i < actions.length) ? actions[i] : null;
        open = false;
        if (a) a();
    }
    function hide() {
        open = false;
    }
}
