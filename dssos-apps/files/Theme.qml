pragma Singleton
import QtQuick

QtObject {
    // Palette stricte DssOS (FILES_DESIGN.md)
    readonly property color bg: "#000000"
    readonly property color rail: "#080808"
    readonly property color side: "#050505"
    readonly property color card: "#131313"
    readonly property color divider: "#232323"
    readonly property color dividerSide: "#1c1c1c"
    readonly property color text: "#f0f0f0"
    readonly property color muted: "#8c8c8c"
    readonly property color accent: "#34c77b"
    readonly property color danger: "#e5484d"
    readonly property color selected: "#1b1b1b"
    readonly property color control: "#0a0a0a"
    readonly property color rowHover: "#0d0d0d"

    // Dimensions et métriques
    readonly property int toolbarHeight: 44
    readonly property int sidebarWidth: 200
    readonly property int previewWidth: 230
    readonly property int statusBarHeight: 26
    readonly property int listHeaderHeight: 30
    readonly property int listRowHeight: 32

    // Polices
    readonly property string fontFamily: "sans-serif"
    readonly property int fontSizeNormal: 13
    readonly property int fontSizeSmall: 11
    readonly property int fontSizeHeader: 12
    readonly property int fontSizeTitle: 14
}
