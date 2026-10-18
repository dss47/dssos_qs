pragma Singleton
import QtQuick
import Quickshell

QtObject {
    // Same idea as the shell's ShellPaths.qml, but for the dssos-apps process.
    //
    // The two cannot share one singleton: they are separate OS processes with
    // separate QML engines, so a copy per process is the price of the split.
    // Both read the same environment, so both derive the same paths.

    readonly property string configDir:
        Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")
    readonly property string quickshellDir: configDir + "/quickshell"

    // The shell process: shell.qml, not the dssos/ folder.
    readonly property string shellEntry: quickshellDir + "/dssos/shell.qml"

    readonly property string appsHost: quickshellDir + "/dssos-apps/apps.qml"
}
