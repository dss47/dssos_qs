pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Settings, as seen from the shell process.
//
// The canonical SettingsState lives in dssos-apps, which is a SEPARATE OS
// process. Two consequences, both of which used to be bugs:
//
//   1. Setting `Style.accent = ...` from the apps process writes to a different
//      Style singleton instance than the one the taskbar reads. The accent
//      colour picked in Settings never reached the shell at all.
//   2. Referencing the shell's own SettingsState from the shell to fix that
//      would construct it -- and that singleton starts eight processes plus a
//      15-second battery poll, in the process that must stay cheap on an
//      i7-7600U.
//
// So the shell does not use SettingsState at all. It watches the one file both
// processes already agree on, which costs one inotify watch and no child
// process at all.
QtObject {
    id: shell

    readonly property string configPath:
        (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config")
        + "/dssos/settings.json"

    // Defaults mirror SettingsState so the shell looks right before the file
    // exists (first boot, or a fresh ISO account).
    property string accent: "green"
    property int barHeight: 34
    property int flyoutGap: 8
    property bool notificationsEnabled: true
    property bool doNotDisturb: false

    property bool loaded: false

    // Forces construction of the lazy _view binding and does the first read.
    //
    // Called from shell.qml's Component.onCompleted. That explicit kick is
    // needed because this is a QtObject singleton: it has no default property
    // (so no child) and Component.onCompleted does not fire for it, while
    // `property var _view:` stays unbuilt until something reads it.
    property bool started: false

    function ensureStarted() {
        if (shell.started) return;
        shell.started = true;
        // Reading text() constructs the FileView and pulls the current contents.
        applyJson(_view.text());
    }

    function applyJson(text: string) {
        let d;
        try {
            d = JSON.parse(text);
        } catch (e) {
            // A half-written file is not worth crashing the shell over; the next
            // write will be complete and trigger another dataChanged.
            console.log("ShellState: bad settings JSON:", e);
            return;
        }
        if (d.accent !== undefined) shell.accent = d.accent;
        if (d.barHeight !== undefined) shell.barHeight = d.barHeight;
        if (d.flyoutGap !== undefined) shell.flyoutGap = d.flyoutGap;
        if (d.notificationsEnabled !== undefined)
            shell.notificationsEnabled = d.notificationsEnabled;
        if (d.doNotDisturb !== undefined)
            shell.doNotDisturb = d.doNotDisturb;

        shell.loaded = true;

        // Push into Style, which is in THIS process and is what the taskbar,
        // menus and flyouts actually read.
        Style.accentName = shell.accent;
        Style.barHeight = shell.barHeight;
        Style.flyoutGap = shell.flyoutGap;
    }

    // A property binding is lazy: `property var _view: FileView {...}` is only
    // built the first time something READS _view, and nothing reads it, so the
    // watch would silently never exist. This is the same trap that made
    // loadProc never run in SettingsState.
    //
    // It cannot be a plain child either: QtObject has no default property, so
    // `FileView { }` as a direct child is a hard error. _forceInit is the
    // idiom already used in this codebase for exactly this.
    property var _forceInit: [_view]

    property var _view: FileView {
        id: view
        path: shell.configPath
        // blockLoading must stay false: with it true, FileView does not read
        // anything until text() is called, so `loaded` never flips and
        // dataChanged never fires -- the watch silently does nothing.
        blockLoading: false
        watchChanges: true
        preload: true
        onDataChanged: shell.applyJson(view.text())
        // The file is created by the first save(); before that there is
        // nothing to read and the defaults above stand.
        onLoadedChanged: if (view.loaded) shell.applyJson(view.text())
    }

    // Style is a sibling singleton in the same module.
    function _forceStyle() { return Style; }
}
