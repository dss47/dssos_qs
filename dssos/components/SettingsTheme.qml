pragma Singleton
import QtQuick

// DssOS Settings theme: Black skin.
// Flat opaque colors allow the Qt Scene Graph to batch geometry into minimal draw calls.
QtObject {
    readonly property color bg: "#000000"
    readonly property color rail: "#080808"
    readonly property color list: "#050505"
    readonly property color card: "#121212"
    readonly property color divider: "#222222"
    readonly property color edge: "#1c1c1c"
    readonly property color text: "#f0f0f0"
    readonly property color muted: "#8c8c8c"
    readonly property color accent: "#34c77b"
    readonly property color accentDark: "#04130a"
    readonly property color selected: "#1b1b1b"
    readonly property color hover: "#111111"
    readonly property color control: "#0a0a0a"
    readonly property color controlHover: "#161616"
    readonly property color danger: "#e05252"
}
