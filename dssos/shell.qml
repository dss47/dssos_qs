import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

// Entry file. Run with: qs -p shell.qml
// Later copy this whole folder to ISO as quickshell config.
import "components/" as Comp
ShellRoot {
    Comp.Desktop {}
    Comp.Taskbar {}
    Comp.QuickSettings {}
    Comp.StartMenu {}
    Comp.HiddenTray {}
    Comp.ContextMenu {}

    // SUPER tap: qs -c $qsConfig ipc call start toggle
    IpcHandler {
        target: "start"
        function toggle(): void { Comp.BarState.startOpen = !Comp.BarState.startOpen; }
        function open(): void { Comp.BarState.startOpen = true; }
        function close(): void { Comp.BarState.startOpen = false; }
    }

    IpcHandler {
        target: "context"
        function hide(): void { Comp.ContextMenuState.hide(); }
    }
}
