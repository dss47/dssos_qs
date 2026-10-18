pragma Singleton
import QtQuick
import Qt.labs.platform as Platform
import Quickshell
import Quickshell.Io

// Single source of truth for well-known locations.
//
// The Files app used to hardcode "/home/saad" in eleven places across five
// files. That breaks the moment the account has a different name -- including
// a fresh DssOS install -- and it means "Home" in the sidebar can point at a
// directory that does not belong to the logged-in user.
QtObject {
    id: paths

    // StandardPaths returns a QUrl ("file:///home/saad"), not a bare path. Every
    // comparison here is against a real filesystem path, so convert once and
    // use plain strings everywhere else.
    function toPath(u) {
        let s = (u === undefined || u === null) ? "" : u.toString();
        if (s.indexOf("file://") === 0) s = s.substring(7);
        return decodeURIComponent(s);
    }

    // Real home of whoever is logged in. Never hardcode this.
    property string home: paths.toPath(
        Platform.StandardPaths.writableLocation(Platform.StandardPaths.HomeLocation))

    property string desktop: paths.toPath(
        Platform.StandardPaths.writableLocation(Platform.StandardPaths.DesktopLocation))
    property string documents: paths.toPath(
        Platform.StandardPaths.writableLocation(Platform.StandardPaths.DocumentsLocation))
    property string downloads: paths.toPath(
        Platform.StandardPaths.writableLocation(Platform.StandardPaths.DownloadLocation))
    property string music: paths.toPath(
        Platform.StandardPaths.writableLocation(Platform.StandardPaths.MusicLocation))
    property string pictures: paths.toPath(
        Platform.StandardPaths.writableLocation(Platform.StandardPaths.PicturesLocation))
    property string videos: paths.toPath(
        Platform.StandardPaths.writableLocation(Platform.StandardPaths.MoviesLocation))

    // XDG trash is not exposed by StandardPaths; this is the freedesktop
    // location, matching the Sidebar's Trash entry.
    property string trash: home + "/.local/share/Trash/files"

    // ------------------------------------------------------------------
    // Clipboard
    //
    // The bytes live on the real Wayland clipboard (wl-clipboard), so a file
    // copied here can be pasted into Dolphin, a browser or a terminal, and
    // Ctrl+V also picks up whatever another application copied.
    //
    // What stays here is only what no MIME type can express: whether the intent
    // was copy or CUT. Everything else is read back from the clipboard on
    // demand, which is why this survives a restart of the apps host -- the
    // clipboard itself does, and wl-copy's owner process outlives us.
    property string clipboardAction: ""   // "copy" | "cut" | ""
    property string clipboardPaths: ""     // newline-separated, our own copy only

    // Files must travel as a text/uri-list, one file:// URI per line. That is
    // the format every other Wayland/X11 tool understands, and it is what makes
    // Ctrl+V work across applications instead of only inside this one.
    //
    // A raw path is NOT a valid uri-list entry, so the previous
    // `wl-copy <path>` advertised text/plain only: pasting into another file
    // manager had nothing to read.
    function dirname(p) {
        const s = String(p);
        const i = s.lastIndexOf("/");
        if (i < 0) return ".";
        if (i === 0) return "/";       // "/file" -> "/", not ""
        return s.substring(0, i);
    }

    function toUri(path) {
        // Encode per segment: encodeURIComponent would escape the slashes too.
        return "file://" + String(path).split("/").map(encodeURIComponent).join("/");
    }

    function fromUri(uri) {
        let s = String(uri).trim();
        if (s.indexOf("file://") === 0) s = s.substring(7);
        try { return decodeURIComponent(s); } catch (e) { return s; }
    }

    // Only text/uri-list lines are URIs; the format allows # comments, which
    // some clipboard managers add, so they are dropped rather than turned into
    // a path called "#comment".
    function parseUriList(text) {
        const out = [];
        const lines = String(text).split("\n");
        for (let i = 0; i < lines.length; ++i) {
            const line = lines[i].trim();
            if (line === "" || line.charAt(0) === "#") continue;
            if (line.indexOf("file://") !== 0) continue;
            out.push(fromUri(line));
        }
        return out;
    }

    // Publish to the system clipboard.
    //
    // The payload is passed as an argv element rather than on stdin: with
    // stdinEnabled the pipe stays open for the lifetime of the Process, so the
    // child never exits and onExited never fires. wl-copy forks itself into the
    // background and keeps serving the selection, which is what makes the data
    // outlive this process.
    function writeClipboard(paths) {
        if (!paths || paths.length === 0) return false;
        const list = [];
        for (let i = 0; i < paths.length; ++i) list.push(toUri(paths[i]));

        clipboardPaths = paths.join("\n");
        // No --foreground: wl-copy must fork into the background and keep
        // serving the selection. Foregrounded it would stay alive as our child
        // and onExited would never fire.
        _clipProc.command = ["wl-copy", "--type", "text/uri-list", list.join("\n")];
        Qt.callLater(function () { _clipProc.running = true; });
        return true;
    }

    property var _clipProc: Process {
        running: false
    }

    // Read the clipboard back. Asynchronous on purpose: wl-paste blocks until the
    // owning process answers, and the owner may be any application.
    //
    // `timeout` guards the empty-clipboard case -- with no owner, wl-paste waits
    // forever and the app would hang instead of just reporting nothing to paste.
    //
    // done(kind, text) is called with kind = "uris" | "text" | "".
    function readClipboard(done) {
        _pasteDone = done;
        _typeProc.command = ["timeout", "2", "wl-paste", "--list-types"];
        Qt.callLater(function () { _typeProc.running = true; });
    }

    property var _pasteDone: null

    // Two processes rather than one with a switched collector: a single Process
    // would need its stdout binding flipped between runs, and the collector
    // would still hold the previous run's text, which is exactly the kind of
    // stale state that turns a file paste into a one-character paste.
    property var _typesOut: StdioCollector { }
    property var _dataOut: StdioCollector { }

    property var _typeProc: Process {
        running: false
        stdout: paths._typesOut
        onExited: (code) => {
            let want = "";
            if (code === 0) {
                const types = (paths._typesOut.text || "").split("\n");
                for (let i = 0; i < types.length; ++i) {
                    const t = types[i].trim();
                    if (t === "text/uri-list") { want = "text/uri-list"; break; }
                    if (t === "text/plain" && want === "") want = "text/plain";
                }
            }
            if (want === "") {
                const done0 = paths._pasteDone;
                paths._pasteDone = null;
                if (done0) done0("", "");
                return;
            }
            _dataProc.command = ["timeout", "2", "wl-paste", "-t", want, "--no-newline"];
            Qt.callLater(function () { _dataProc.running = true; });
        }
    }

    property var _dataProc: Process {
        running: false
        stdout: paths._dataOut
        onExited: (code) => {
            const done = paths._pasteDone;
            paths._pasteDone = null;
            if (!done) return;
            if (code !== 0) { done("", ""); return; }
            // Decide by content, not by the advertised type: some owners
            // advertise text/uri-list but hand back plain text, and a path
            // copied by hand elsewhere must still paste.
            const data = paths._dataOut.text || "";
            done(data.indexOf("file://") === 0 ? "uris" : "text", data);
        }
    }

    // "/home/saad/Pictures" -> "~/Pictures", for display only.
    function tilde(p) {
        if (!p) return "";
        if (p === home) return "~";
        if (p.indexOf(home + "/") === 0) return "~" + p.substring(home.length);
        return p;
    }

    function isUnderHome(p) {
        return !!p && (p === home || p.indexOf(home + "/") === 0);
    }

    // Standard XDG user directories, created on first use.
    //
    // This is not just tidiness. With no ~/.config/user-dirs.dirs, Qt's
    // StandardPaths falls back to DesktopLocation for any location it cannot
    // resolve, so "Videos" pointed at ~/Desktop and clicking either sidebar
    // row highlighted BOTH of them.
    //
    // Deliberately ONE process for the whole job (mkdir + write the XDG file),
    // so `ready` flips a single time off one exit signal. Chaining two
    // Processes through onExited left ready stuck at false, and the sidebar is
    // gated on it -- which would have hidden every place.
    //
    // $1 is the file content, $2..$9 the directories, $10 the XDG file path.
    // Nothing is shell-interpolated: every value arrives as a positional
    // argument, and the content keeps a literal $HOME, which is what the XDG
    // spec expects consumers to expand.
    readonly property var standardDirs: [
        "Desktop", "Documents", "Downloads", "Music", "Pictures", "Videos"
    ]

    function ensureStandardDirs() {
        const dirs = [home + "/.config"];
        for (let i = 0; i < paths.standardDirs.length; ++i)
            dirs.push(home + "/" + paths.standardDirs[i]);
        dirs.push(trash);

        Quickshell.execDetached(["mkdir", "-p"].concat(dirs));
        Quickshell.execDetached(["sh", "-c", 'if [ ! -f "$HOME/.config/user-dirs.dirs" ]; then printf "%s" "$1" > "$HOME/.config/user-dirs.dirs"; fi', "sh", _xdgContent()]);
        paths._reResolve();
    }

    function ensureDirectory(path) {
        if (!path || path === "/" || path === home) return;
        Quickshell.execDetached(["mkdir", "-p", path]);
    }

    function _xdgContent() {
        return 'XDG_DESKTOP_DIR="$HOME/Desktop"\n'
             + 'XDG_DOCUMENTS_DIR="$HOME/Documents"\n'
             + 'XDG_DOWNLOAD_DIR="$HOME/Downloads"\n'
             + 'XDG_MUSIC_DIR="$HOME/Music"\n'
             + 'XDG_PICTURES_DIR="$HOME/Pictures"\n'
             + 'XDG_VIDEOS_DIR="$HOME/Videos"\n';
    }

    // false until ensureStandardDirs() has finished, so the sidebar can wait
    // for a fully-resolved place list instead of a partly-fallbacked one.
    property bool ready: false

    function _reResolve() {
        home = toPath(Platform.StandardPaths.writableLocation(Platform.StandardPaths.HomeLocation));
        desktop = toPath(Platform.StandardPaths.writableLocation(Platform.StandardPaths.DesktopLocation));
        documents = toPath(Platform.StandardPaths.writableLocation(Platform.StandardPaths.DocumentsLocation));
        downloads = toPath(Platform.StandardPaths.writableLocation(Platform.StandardPaths.DownloadLocation));
        music = toPath(Platform.StandardPaths.writableLocation(Platform.StandardPaths.MusicLocation));
        pictures = toPath(Platform.StandardPaths.writableLocation(Platform.StandardPaths.PicturesLocation));
        videos = toPath(Platform.StandardPaths.writableLocation(Platform.StandardPaths.MoviesLocation));
        trash = home + "/.local/share/Trash/files";
        ready = true;
    }

    property var _ensureProc: Process {
        running: false
        onExited: paths._reResolve()
    }


    // Places offered in the sidebar, in order.
    //
    // Duplicate paths are dropped as a safety net: even with the directories
    // created, any location that still resolves onto another (an unusual
    // XDG config) would otherwise highlight two rows at once.
    function standardPlaces() {
        const candidates = [
            { name: "Home",      icon: "user-home",      path: home,      dir: null },
            { name: "Desktop",   icon: "user-desktop",   path: desktop,   dir: "Desktop" },
            { name: "Documents", icon: "folder-documents", path: documents, dir: "Documents" },
            { name: "Downloads", icon: "folder-download", path: downloads, dir: "Downloads" },
            { name: "Pictures",  icon: "folder-pictures", path: pictures,  dir: "Pictures" },
            { name: "Music",     icon: "folder-music",    path: music,     dir: "Music" },
            { name: "Videos",    icon: "folder-videos",   path: videos,    dir: "Videos" },
            { name: "Trash",     icon: "user-trash",      path: trash,     dir: null }
        ];

        const seen = {};
        const out = [];
        for (let i = 0; i < candidates.length; ++i) {
            const c = candidates[i];
            const conventional = c.dir ? (home + "/" + c.dir).replace(/\/+$/, "") : "";
            let p = (c.path || "").replace(/\/+$/, "");
            let key = p;

            if (!p) {
                // Qt could not resolve it at all.
                if (!conventional || seen[conventional]) continue;
                key = conventional;
            } else if (seen[key]) {
                // Collision: this location points somewhere another entry
                // already claims (Videos -> Desktop when XDG is unresolved).
                // Prefer the conventional directory so every place still gets
                // its own row instead of two rows highlighting together.
                if (!conventional || seen[conventional]) continue;
                key = conventional;
                p = conventional;
            }

            seen[key] = true;
            out.push({ name: c.name, icon: c.icon, path: p });
        }
        return out;
    }
}
