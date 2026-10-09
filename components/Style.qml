pragma Singleton
import QtQuick

// One palette for the whole shell. No raw hex in components.
QtObject {
    readonly property color surface: "#101010"
    readonly property color card: "#1f1f1f"
    readonly property color cardHi: "#2e2e2e"
    readonly property color border: "#2d2d2d"
    readonly property color borderSoft: "#552d2d2d"
    readonly property color text: "#ffffff"
    readonly property color dim: "#9a9cb5"
    readonly property color green: "#1e9e57"
    readonly property color amber: "#bd8f2a"
    readonly property color danger: "#e05561"

    // taskbar geometry
    readonly property int barHeight: 48
    readonly property color barEdge: "#CC141414"
    readonly property color barMid: "#CC000000"

    // flyouts sit one gap above the bar
    readonly property int flyoutBottom: 56

    // motion: flyouts glide, menus fade fast (untouched, 120/100)
    readonly property int slideIn: 200
    readonly property int slideOut: 180

    // feedback strength
    readonly property real hover: 0.15
    readonly property real press: 0.3
}
