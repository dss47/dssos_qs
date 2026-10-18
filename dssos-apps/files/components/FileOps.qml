import QtQuick
import Quickshell.Io

// File mutations for the Files app.
QtObject {
    id: ops

    signal finished(string op, bool ok, string message, string extra)
    signal folderCreated(string path, string name)
    signal fileCreated(string path, string name)

    property bool _started: false

    property var _proc: Process {
        running: false
        stdout: StdioCollector { id: outCol }
        stderr: StdioCollector { id: errCol }
        onRunningChanged: {
            if (running) {
                ops._started = true;
            } else if (!ops._started && ops._pendingOp !== "") {
                // Quickshell failed to spawn the process (e.g. binary not found)
                // In Quickshell, onExited never fires in this case; runningChanged fires with false.
                ops._finishCurrent(false, ops._errorFrom(-1), "");
            }
        }
        onExited: (code) => {
            const outText = outCol.text ? outCol.text.trim() : "";
            const errText = errCol.text ? errCol.text.trim() : "";
            const ok = code === 0;
            ops._finishCurrent(ok, ok ? "" : (errText || ops._errorFrom(code)), outText);
        }
    }

    property string _pendingOp: ""
    property var _errorFrom: function (c) { return "Operation failed"; }
    property var _queue: []

    function _finishCurrent(ok, errText, outText) {
        if (ops._pendingOp === "") return;
        const op = ops._pendingOp;
        ops._pendingOp = "";
        ops._errorFrom = function (c) { return "Operation failed"; };

        if (op === "mkdir" && ok) {
            // Newline-delimited format avoids colon delimiter collisions with paths:
            // CREATED\n<dir_path>\n<folder_name>
            const lines = outText.split("\n");
            if (lines.length >= 3 && lines[0] === "CREATED") {
                ops.folderCreated(lines[1], lines[2]);
            }
        } else if (op === "mkfile" && ok) {
            const lines = outText.split("\n");
            if (lines.length >= 3 && lines[0] === "CREATED") {
                ops.fileCreated(lines[1], lines[2]);
            }
        }

        ops.finished(op, ok, ok ? "" : errText, outText);
        ops._queue.shift();
        if (ops._queue.length > 0) {
            Qt.callLater(ops._pump);
        }
    }

    function run(op, command, describeFailure) {
        _queue.push({
            op: op,
            command: command,
            describeFailure: describeFailure || function (c) { return "Operation failed"; }
        });
        if (!_proc.running && _pendingOp === "") {
            _pump();
        }
    }

    function _pump() {
        if (_queue.length === 0 || _proc.running || _pendingOp !== "") return;
        const next = _queue[0];
        _pendingOp = next.op;
        _errorFrom = next.describeFailure;
        _started = false;
        _proc.command = next.command;
        _proc.running = true;
    }

// Every bash loop in this file ends with `done`, and `done` takes the exit
// status of the LAST command in the loop body. When that command is an `if`
// construct it always succeeds, so a loop in which every single operation
// failed still exited 0: the status bar announced "Pasted", "Moved to Trash"
// or "Deleted", and Files pushed an undo entry for files it had never
// touched. Each script now carries an explicit rc and ends with `exit $rc`.
//

    // ---------------------------------------------------------------- create

    function createFolder(parentDir, name) {
        const baseName = (name && name.trim()) ? name.trim() : "New folder";
        const script =
            'p="$1"; n="$2"; d="$p/$n"; ' +
            'if [ -e "$d" ]; then ' +
            '  c=1; while [ -e "$p/${n} (${c})" ]; do c=$((c + 1)); done; ' +
            '  n="${n} (${c})"; d="$p/$n"; ' +
            'fi; ' +
            'if mkdir -p -- "$d"; then printf "CREATED\\n%s\\n%s\\n" "$d" "$n"; else exit 1; fi';
        run("mkdir", ["bash", "-c", script, "--", parentDir, baseName], function () {
            return "Could not create folder in \"" + parentDir + "\"";
        });
    }

    function createFile(parentDir, name) {
        const full = (name && name.trim()) ? name.trim() : "New Document.txt";
        if (full.indexOf("/") !== -1 || full === "." || full === "..") {
            ops.finished("mkfile", false, "A name cannot contain \"/\", \".\" or \"..\"", "");
            return;
        }
        const script =
            'p="$1"; full="$2"; ' +
            'if [[ "$full" == .* && "$full" != *.*.* ]]; then base="$full"; ext=""; ' +
            'elif [[ "$full" == *.* ]]; then ext=".${full##*.}"; base="${full%.*}"; ' +
            'else ext=""; base="$full"; fi; ' +
            'n="$full"; f="$p/$n"; ' +
            'if [ -e "$f" ]; then ' +
            '  c=1; while [ -e "$p/${base} (${c})${ext}" ]; do c=$((c + 1)); done; ' +
            '  n="${base} (${c})${ext}"; f="$p/$n"; ' +
            'fi; ' +
            'if touch -- "$f"; then printf "CREATED\\n%s\\n%s\\n" "$f" "$n"; else exit 1; fi';
        run("mkfile", ["bash", "-c", script, "--", parentDir, full], function () {
            return "Could not create file in \"" + parentDir + "\"";
        });
    }

    // ---------------------------------------------------------------- rename

    function rename(oldPath, newName) {
        if (!newName || newName.trim() === "") {
            ops.finished("rename", false, "Name cannot be empty", "");
            return;
        }
        const name = newName.trim();

        // The name is concatenated straight into the target path, so a name
        // holding a slash or a dot-dot does not stay inside the folder. The
        // rename field accepted "a/../../elsewhere" and ".." and quietly moved
        // the file somewhere the user never pointed at.
        if (name.indexOf("/") !== -1 || name === "." || name === "..") {
            ops.finished("rename", false, "A name cannot contain \"/\", \".\" or \"..\"", "");
            return;
        }

        const dir = oldPath.substring(0, oldPath.lastIndexOf("/"));
        const target = dir + "/" + name;
        if (target === oldPath) {
            ops.finished("rename", false, "", "");
            return;
        }

        // Refusing to overwrite needs two things, and only doing one of them is
        // a trap:
        //
        //   `mv -T -- src dst` replaces dst outright. No prompt, no backup, no
        //   undo entry -- renaming onto an existing file destroyed it. Verified:
        //   the target's contents were replaced.
        //
        //   `mv -nT -- src dst` leaves the target alone, but it exits 0 when it
        //   skips. So FileOps reported "Renamed" and pushed an undo entry while
        //   nothing at all had moved. Also verified on the VM.
        //
        // So the existence test runs first and produces a distinct exit code,
        // and -n stays as the guard for the race between the two.
        const script =
            'if [ -e "$2" ]; then echo "RENAMEEXISTS"; exit 3; fi; ' +
            'mv -nT -- "$1" "$2" || exit 1; ' +
            'echo "RENAMED:$2"';
        run("rename", ["bash", "-c", script, "--", oldPath, target], function () {
            return "Could not rename to \"" + name + "\"";
        });
    }

    // ---------------------------------------------------------------- clipboard (copy / cut)

    // One shell loop over every source instead of one process per file: the
    // collision-suffixing has to see the files already created in this same run,
    // otherwise pasting "a.txt" twice into the same folder yields "a (1).txt"
    // and "a (1).txt" again for the second, silently clobbering nothing but
    // producing the same name twice.
    //
    // "$@" after `shift` keeps every path a separate argument, so names with
    // spaces or quotes survive; nothing is interpolated into the script text.
    function copyItems(srcs, destDir) {
        if (!srcs || srcs.length === 0) return;
        const script =
            'd="$1"; shift; ' +
            'rc=0; ' +
            'for s in "$@"; do ' +
            '  base="$(basename "$s")"; target="$d/$base"; ' +
            '  if [ -e "$target" ]; then ' +
            '    ext="${base##*.}"; name="${base%.*}"; ' +
            '    if [ "$ext" = "$base" ]; then ext=""; else ext=".$ext"; fi; ' +
            '    if [ -z "$name" ] && [ -n "$ext" ]; then name="$ext"; ext=""; fi; ' +
            '    c=1; while [ -e "$d/${name} (${c})${ext}" ]; do c=$((c + 1)); done; ' +
            '    target="$d/${name} (${c})${ext}"; ' +
            '  fi; ' +
            '  if cp -r -- "$s" "$target"; then echo "COPIED:$target"; else rc=1; fi; ' +
            'done; ' +
            'exit $rc';
        const cmd = ["bash", "-c", script, "--", destDir].concat(srcs);
        run("copy", cmd, function () {
            return "Could not paste into \"" + destDir + "\"";
        });
    }

    function moveItems(srcs, destDir) {
        if (!srcs || srcs.length === 0) return;
        const script =
            'd="$1"; shift; ' +
            'rc=0; ' +
            'for s in "$@"; do ' +
            '  base="$(basename "$s")"; target="$d/$base"; ' +
            '  if [ -e "$target" ]; then ' +
            '    ext="${base##*.}"; name="${base%.*}"; ' +
            '    if [ "$ext" = "$base" ]; then ext=""; else ext=".$ext"; fi; ' +
            '    if [ -z "$name" ] && [ -n "$ext" ]; then name="$ext"; ext=""; fi; ' +
            '    c=1; while [ -e "$d/${name} (${c})${ext}" ]; do c=$((c + 1)); done; ' +
            '    target="$d/${name} (${c})${ext}"; ' +
            '  fi; ' +
            '  if mv -- "$s" "$target"; then echo "MOVED:$target"; else rc=1; fi; ' +
            'done; ' +
            'exit $rc';
        const cmd = ["bash", "-c", script, "--", destDir].concat(srcs);
        run("cut", cmd, function () {
            return "Could not move into \"" + destDir + "\"";
        });
    }

    // Single-item entry points kept because the undo stack and the trash
    // restore path still call them by name.
    function copyItem(src, destDir) { copyItems([src], destDir); }
    function moveItem(src, destDir) { moveItems([src], destDir); }

    // Text that was not a file (copied from a browser, a terminal, a chat).
    // A file manager has nothing to paste here, so it becomes a new document
    // rather than being silently dropped.
    function pasteText(text, destDir) {
        const script =
            'd="$1"; t="$2"; n="Pasted Text.txt"; rc=0; ' +
            'if [ -e "$d/$n" ]; then ' +
            '  c=1; while [ -e "$d/Pasted Text (${c}).txt" ]; do c=$((c + 1)); done; ' +
            '  n="Pasted Text (${c}).txt"; ' +
            'fi; ' +
            'if printf "%s" "$t" > "$d/$n"; then echo "CREATED:$d/$n"; else rc=1; fi; ' +
            'exit $rc';
        // The text is an argv element, so embedded newlines, quotes and even a
        // leading "-" are data rather than syntax.
        run("paste_text", ["bash", "-c", script, "--", destDir, text], function () {
            return "Could not write into \"" + destDir + "\"";
        });
    }

    // ---------------------------------------------------------------- trash

    // Accepts one path or a list. After Ctrl+A every caller used to pass
    // win.selectedItem -- the active row -- while the highlight covered the
    // whole folder, so Delete threw away all but one of the selected items.
    //
    // One shell loop rather than one gio per path: gio has no multi-target form,
    // and separate runs would flicker the status bar N times and hide which
    // item refused. "$@" keeps every name intact.
    function trash(path) {
        const list = Array.isArray(path) ? path : [path];
        if (list.length === 0) return;
        const script =
            'rc=0; ' +
            'for p in "$@"; do ' +
            '  if gio trash -- "$p" 2>/dev/null; then echo "TRASHED:$p"; ' +
            '  else echo "TRASHFAILED:$p"; rc=1; fi; ' +
            'done; ' +
            'exit $rc';
        run("trash", ["bash", "-c", script, "--"].concat(list), function () {
            return "Cannot Trash on this filesystem \u2014 press Shift+Delete to delete permanently";
        });
    }

    function restoreTrash(pathOrName) {
        // Accepts a list: the Delete undo restores every trashed item at once,
        // and before this it called restoreTrash once per item -- but all of
        // those calls shared the single _proc, so each one overwrote the
        // previous command and only the last file was ever restored.
        //
        // Two other fixes inside the script:
        // - the trash root honours XDG_DATA_HOME instead of assuming
        //   ~/.local/share, which is where gio puts it when the variable is set;
        // - an existing file at the original path is no longer overwritten.
        const pyScript =
            'import os, sys, glob, shutil, urllib.parse\n' +
            'home = os.path.expanduser("~")\n' +
            'data = os.environ.get("XDG_DATA_HOME") or os.path.join(home, ".local", "share")\n' +
            'trash = os.path.join(data, "Trash")\n' +
            '\n' +
            'def locate(target):\n' +
            '    base = os.path.basename(target)\n' +
            '    info = os.path.join(trash, "info", base + ".trashinfo")\n' +
            '    fpath = os.path.join(trash, "files", base)\n' +
            '    if os.path.exists(info) and os.path.exists(fpath):\n' +
            '        return info, fpath\n' +
            '    hits = []\n' +
            '    for inf in glob.glob(os.path.join(trash, "info", "*.trashinfo")):\n' +
            '        try:\n' +
            '            with open(inf, "r", encoding="utf-8") as f:\n' +
            '                for line in f:\n' +
            '                    if line.startswith("Path="):\n' +
            '                        if urllib.parse.unquote(line.split("=", 1)[1].strip()) == target:\n' +
            '                            hits.append((os.path.getmtime(inf), inf))\n' +
            '                        break\n' +
            '        except Exception:\n' +
            '            pass\n' +
            '    if not hits:\n' +
            '        return None, None\n' +
            '    hits.sort(reverse=True)\n' +
            '    info = hits[0][1]\n' +
            '    return info, os.path.join(trash, "files", os.path.basename(info)[:-len(".trashinfo")])\n' +
            '\n' +
            'def original_of(info):\n' +
            '    with open(info, "r", encoding="utf-8") as f:\n' +
            '        for line in f:\n' +
            '            if line.startswith("Path="):\n' +
            '                return urllib.parse.unquote(line.split("=", 1)[1].strip())\n' +
            '    return None\n' +
            '\n' +
            'rc = 0\n' +
            'for target in sys.argv[1:]:\n' +
            '    info, fpath = locate(target)\n' +
            '    if info is None:\n' +
            '        sys.stderr.write("Trash metadata not found\\n"); rc = 1; continue\n' +
            '    orig = original_of(info)\n' +
            '    if not orig:\n' +
            '        sys.stderr.write("No Path in metadata\\n"); rc = 1; continue\n' +
            '    # shutil.move() replaces whatever is at the destination without asking.\n' +
            '    # Restoring over a file the user re-created in the meantime destroyed that\n' +
            '    # file, so refuse instead and report it.\n' +
            '    if os.path.exists(orig):\n' +
            '        sys.stderr.write("Already exists: %s\\n" % orig); rc = 1; continue\n' +
            '    os.makedirs(os.path.dirname(orig), exist_ok=True)\n' +
            '    shutil.move(fpath, orig)\n' +
            '    os.remove(info)\n' +
            '    print("RESTORED:%s:%s" % (orig, os.path.basename(target)))\n' +
            'sys.exit(rc)\n';
        const list = Array.isArray(pathOrName) ? pathOrName : [pathOrName];
        if (list.length === 0) return;
        run("restore", ["python3", "-c", pyScript].concat(list), function () {
            return list.length === 1
                ? "Could not restore \"" + list[0].split("/").pop() + "\" from Trash"
                : "Could not restore " + list.length + " items from Trash";
        });
    }

    function emptyTrash() {
        const script = 'find "$HOME/.local/share/Trash/files" "$HOME/.local/share/Trash/info" -mindepth 1 -delete 2>/dev/null || true';
        run("empty_trash", ["bash", "-c", script], function () {
            return "Could not empty Trash";
        });
    }

    // Accepts one path or a list. -rf for the batch: a multi-selection is
    // collapsed to plain paths, and rm -f on a directory would fail and skip it.
    function permanentDelete(path, isDir) {
        const list = Array.isArray(path) ? path : [path];
        if (list.length === 0) return;
        const script =
            'rc=0; ' +
            'for p in "$@"; do ' +
            '  if rm -rf -- "$p"; then echo "DELETED:$p"; else echo "DELETEFAILED:$p"; rc=1; fi; ' +
            'done; ' +
            'exit $rc';
        run("permanent", ["bash", "-c", script, "--"].concat(list), function () {
            return list.length === 1
                ? "Could not delete \"" + list[0].split("/").pop() + "\""
                : "Could not delete " + list.length + " items";
        });
    }
}