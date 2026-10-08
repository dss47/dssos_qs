import QtQuick
import Quickshell
import Quickshell.Wayland

// Entry file. Run with: qs -p shell.qml
// Later copy this whole folder to ISO as quickshell config.
import "components/" as Comp
ShellRoot {
    Comp.Taskbar {}
    Comp.QuickSettings {}
    Comp.StartMenu {}
    Comp.HiddenTray {}
    Comp.ContextMenu {}
}
