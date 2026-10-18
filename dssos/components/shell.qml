import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

// Entry file. Run with: qs -p shell.qml
// Later copy this whole folder to ISO as quickshell config.
import "components/" as Comp
ShellRoot {
    Comp.Taskbar {}
    Comp.QuickSettings {}
    Comp.StartMenu {}
    Comp.HiddenTray {}
    Comp.ContextMenu {}
    Comp.Settings {}

    // SUPER tap: qs -c $qsConfig ipc call start toggle
    // (wayfire.ini binds SUPER to this; compositor-independent)
    IpcHandler {
        target: "start"
        function toggle(): void { Comp.BarState.startOpen = !Comp.BarState.startOpen; }
        function open(): void { Comp.BarState.startOpen = true; }
        function close(): void { Comp.BarState.startOpen = false; }
    }

    // Settings IPC: qs -c $qsConfig ipc call settings toggle
    IpcHandler {
        target: "settings"
        function toggle(): void { Comp.SettingsState.open = !Comp.SettingsState.open; }
        function open(): void { Comp.SettingsState.open = true; }
        function close(): void { Comp.SettingsState.open = false; }
    }
}
