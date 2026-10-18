import QtQuick
import Quickshell.Io

// File mutations for the Files app.
QtObject {
    id: ops

    signal finished(string op, bool ok, string message, string extra)
    signal folderCreated(string path, string name)

    property var _proc: Process {
        running: false
        stdout: StdioCollector { id: outCol }
        stderr: StdioCollector { id: errCol }
        onExited: (code) => {
            const outText = outCol.text ? outCol.text.trim() : "";
            const errText = errCol.text ? errCol.text.trim() : "";
            const ok = code === 0;
            const op = ops._pendingOp;

            if (op === "mkdir" && ok) {
                // outText: CREATED:path:name
                if (outText.startsWith("CREATED:")) {
                    const parts = outText.split(":");
                    if (parts.length >= 3) {
                        ops.folderCreated(parts[1], parts[2]);
                    }
                }
            }

            ops.finished(op, ok, ok ? "" : (errText || ops._errorFrom(code)), outText);
            ops._pendingOp = "";
            ops._errorFrom = function (c) { return "Operation failed"; };
        }
    }

    property string _pendingOp: ""
    property var _errorFrom: function (c) { return "Operation failed"; }

    function run(op, command, describeFailure) {
        _pendingOp = op;
        _errorFrom = describeFailure || function (c) { return "Operation failed"; };
        _proc.command = command;
        _proc.running = true;
        Qt.callLater(function () { _proc.running = true; });
    }

    // ---------------------------------------------------------------- create

    function createFolder(parentDir, name) {
        const baseName = (name && name.trim()) ? name.trim() : "New folder";
        const script =
            'p="$1"; n="$2"; d="$p/$n"; ' +
            'if [ -e "$d" ]; then ' +
            '  c=1; while [ -e "$p/${n} (${c})" ]; do c=$((c + 1)); done; ' +
            '  n="${n} (${c})"; d="$p/$n"; ' +
            'fi; ' +
            'mkdir -p -- "$d" && echo "CREATED:$d:$n"';
        run("mkdir", ["bash", "-c", script, "--", parentDir, baseName], function () {
            return "Could not create folder in \"" + parentDir + "\"";
        });
    }

    // ---------------------------------------------------------------- rename

    function rename(oldPath, newName) {
        if (!newName || newName.trim() === "") {
            ops.finished("rename", false, "Name cannot be empty", "");
            return;
        }
        const dir = oldPath.substring(0, oldPath.lastIndexOf("/"));
        const target = dir + "/" + newName.trim();
        if (target === oldPath) {
            ops.finished("rename", false, "", "");
            return;
        }
        run("rename", ["mv", "-T", "--", oldPath, target], function () {
            return "Could not rename to \"" + newName.trim() + "\"";
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
            'for s in "$@"; do ' +
            '  base="$(basename "$s")"; target="$d/$base"; ' +
            '  if [ -e "$target" ]; then ' +
            '    ext="${base##*.}"; name="${base%.*}"; ' +
            '    if [ "$ext" = "$base" ]; then ext=""; else ext=".$ext"; fi; ' +
            '    c=1; while [ -e "$d/${name} (${c})${ext}" ]; do c=$((c + 1)); done; ' +
            '    target="$d/${name} (${c})${ext}"; ' +
            '  fi; ' +
            '  if cp -r -- "$s" "$target"; then echo "COPIED:$target"; fi; ' +
            'done';
        const cmd = ["bash", "-c", script, "--", destDir].concat(srcs);
        run("copy", cmd, function () {
            return "Could not paste into \"" + destDir + "\"";
        });
    }

    function moveItems(srcs, destDir) {
        if (!srcs || srcs.length === 0) return;
        const script =
            'd="$1"; shift; ' +
            'for s in "$@"; do ' +
            '  base="$(basename "$s")"; target="$d/$base"; ' +
            '  if [ -e "$target" ]; then ' +
            '    ext="${base##*.}"; name="${base%.*}"; ' +
            '    if [ "$ext" = "$base" ]; then ext=""; else ext=".$ext"; fi; ' +
            '    c=1; while [ -e "$d/${name} (${c})${ext}" ]; do c=$((c + 1)); done; ' +
            '    target="$d/${name} (${c})${ext}"; ' +
            '  fi; ' +
            '  if mv -- "$s" "$target"; then echo "MOVED:$target"; fi; ' +
            'done';
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
            'd="$1"; t="$2"; n="Pasted Text.txt"; ' +
            'if [ -e "$d/$n" ]; then ' +
            '  c=1; while [ -e "$d/Pasted Text (${c}).txt" ]; do c=$((c + 1)); done; ' +
            '  n="Pasted Text (${c}).txt"; ' +
            'fi; ' +
            'printf "%s" "$t" > "$d/$n" && echo "CREATED:$d/$n"';
        // The text is an argv element, so embedded newlines, quotes and even a
        // leading "-" are data rather than syntax.
        run("paste_text", ["bash", "-c", script, "--", destDir, text], function () {
            return "Could not write into \"" + destDir + "\"";
        });
    }

    // ---------------------------------------------------------------- trash

    function trash(path) {
        run("trash", ["gio", "trash", "--", path], function () {
            return "Cannot Trash on this filesystem \u2014 press Shift+Delete to delete permanently";
        });
    }

    function restoreTrash(pathOrName) {
        const pyScript =
            'import os, sys, urllib.parse, glob, shutil\n' +
            'target = sys.argv[1]\n' +
            'trash = os.path.expanduser("~/.local/share/Trash")\n' +
            'base = os.path.basename(target)\n' +
            'info_file = os.path.join(trash, "info", f"{base}.trashinfo")\n' +
            'file_path = os.path.join(trash, "files", base)\n' +
            'if not (os.path.exists(info_file) and os.path.exists(file_path)):\n' +
            '    cands = []\n' +
            '    for inf in glob.glob(os.path.join(trash, "info", "*.trashinfo")):\n' +
            '        try:\n' +
            '            with open(inf, "r", encoding="utf-8") as f:\n' +
            '                for line in f:\n' +
            '                    if line.startswith("Path="):\n' +
            '                        p = urllib.parse.unquote(line.strip().split("=", 1)[1])\n' +
            '                        if p == target:\n' +
            '                            cands.append((os.path.getmtime(inf), inf))\n' +
            '                        break\n' +
            '        except Exception:\n' +
            '            pass\n' +
            '    if not cands:\n' +
            '        sys.stderr.write("Trash metadata not found\\n")\n' +
            '        sys.exit(1)\n' +
            '    cands.sort(reverse=True)\n' +
            '    info_file = cands[0][1]\n' +
            '    bname = os.path.basename(info_file)[:-len(".trashinfo")]\n' +
            '    file_path = os.path.join(trash, "files", bname)\n' +
            'with open(info_file, "r", encoding="utf-8") as f:\n' +
            '    for line in f:\n' +
            '        if line.startswith("Path="):\n' +
            '            orig = urllib.parse.unquote(line.strip().split("=", 1)[1])\n' +
            '            os.makedirs(os.path.dirname(orig), exist_ok=True)\n' +
            '            shutil.move(file_path, orig)\n' +
            '            os.remove(info_file)\n' +
            '            print(f"RESTORED:{orig}:{base}")\n' +
            '            sys.exit(0)\n' +
            'sys.stderr.write("No Path in metadata\\n")\n' +
            'sys.exit(1)\n';
        run("restore", ["python3", "-c", pyScript, pathOrName], function () {
            return "Could not restore \"" + pathOrName.split("/").pop() + "\" from Trash";
        });
    }

    function emptyTrash() {
        const script = 'find "$HOME/.local/share/Trash/files" "$HOME/.local/share/Trash/info" -mindepth 1 -delete 2>/dev/null || true';
        run("empty_trash", ["bash", "-c", script], function () {
            return "Could not empty Trash";
        });
    }

    function permanentDelete(path, isDir) {
        const cmd = isDir ? ["rm", "-rf", "--", path]
                          : ["rm", "-f", "--", path];
        run("permanent", cmd, function () {
            return "Could not delete \"" + path.split("/").pop() + "\"";
        });
    }
}