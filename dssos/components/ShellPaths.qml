pragma Singleton
import QtQuick
import Quickshell

QtObject {
    // These used to sit on a QtObject nested INSIDE the singleton. A singleton
    // root has no default property, so the inner object was never reachable:
    // ShellPaths.appsHost evaluated to undefined and Desktop.qml passed
    // undefined straight into Quickshell.execDetached. They have to be declared
    // directly on the singleton.

    readonly property string configDir:
        Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")
    readonly property string quickshellDir: configDir + "/quickshell"

    // The app host: Settings, Files and Tasks all load inside this one process.
    readonly property string appsHost: quickshellDir + "/dssos-apps/apps.qml"

    // The shell process: shell.qml, not the dssos/ folder.
    readonly property string shellEntry: quickshellDir + "/dssos/shell.qml"

    // USER is not exported in every session -- a bare `su` shell has no login
    // environment -- so fall back to the last segment of the config path
    // instead of rendering an empty label.
    readonly property string userName: {
        const u = Quickshell.env("USER");
        if (u && u !== "") return u;
        const parts = configDir.split("/");
        return parts[parts.length - 1] || "user";
    }
}
