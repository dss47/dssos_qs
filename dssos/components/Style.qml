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
    readonly property color greenBase: "#1e9e57"
    readonly property color amber: "#bd8f2a"
    readonly property color danger: "#e05561"
    readonly property color dangerDeep: "#a33a45"
    readonly property color mint: "#43d884"
    readonly property color logoTop: "#5ff09a"
    readonly property color logoBottom: "#25a75c"

    // Live customizable properties driven by SettingsState
    property string accentName: "green"
    readonly property color green: accentName === "amber" ? amber
                                 : accentName === "mint"  ? mint
                                 : accentName === "danger"? danger
                                 : greenBase

    // taskbar geometry
    property int barHeight: 34
    readonly property color barEdge: "#FF141414"
    readonly property color barMid: "#FF000000"

    // flyouts sit one gap above the bar (tracks barHeight on any screen)
    property int flyoutGap: 8
    readonly property int flyoutBottom: barHeight + flyoutGap

    // motion: flyouts glide, menus fade fast
    property int slideIn: 200
    property int slideOut: 180

    // feedback strength
    readonly property real hover: 0.15
    readonly property real press: 0.3
}
