pragma Singleton
import QtQuick
import Quickshell

// Where the other Quickshell processes live, derived from the environment
// instead of written down.
//
// Both of these were literal "/home/saad/..." strings. That breaks the moment
// the account has another name, and on the live ISO the user is whatever
// `saad` happened to be on the build machine -- so the context menu could not
// dismiss itself for anyone else.
QtObject {
    readonly property string configDir:
        Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")
    readonly property string quickshellDir: configDir + "/quickshell"

    // The app host: Settings, Files and Tasks all load inside this one process.
    readonly property string appsHost: quickshellDir + "/dssos-apps/apps.qml"

    // The shell process: shell.qml, not the dssos/ folder.
    readonly property string shellEntry: quickshellDir + "/dssos/shell.qml"
}
