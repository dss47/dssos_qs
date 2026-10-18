import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

// Entry file. Run with: qs -p shell.qml
// Later copy this whole folder to ISO as quickshell config.
import "components/" as Comp
ShellRoot {
    // Start the settings watch explicitly: ShellState is a QtObject
    // singleton, so it cannot start itself, and without this the taskbar
    // keeps the default accent and bar height no matter what Settings saved.
    Component.onCompleted: Comp.ShellState.ensureStarted()

    Comp.Desktop {}
    Comp.Taskbar {}
    Comp.ContextMenu {}

    // SUPER tap: qs -c $qsConfig ipc call start toggle
    IpcHandler {
        target: "start"
        function toggle(): void { Comp.BarState.startOpen = !Comp.BarState.startOpen; }
        function open(): void { Comp.BarState.startOpen = true; }
        function close(): void { Comp.BarState.startOpen = false; }
    }

    IpcHandler {
        target: "quick"
        function toggle(): void { Comp.BarState.quickOpen = !Comp.BarState.quickOpen; }
        function open(): void { Comp.BarState.quickOpen = true; }
        function close(): void { Comp.BarState.quickOpen = false; }
    }

    IpcHandler {
        target: "context"
        function hide(): void { Comp.ContextMenuState.hide(); }
    }
}
