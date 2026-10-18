pragma Singleton
import QtQuick

QtObject {
    // Palette DssOS stricte (TASKS_DESIGN.md)
    readonly property color bg: "#000000"
    readonly property color sidebar: "#050505"
    readonly property color status: "#080808"
    readonly property color card: "#131313"
    readonly property color divider: "#232323"
    readonly property color dividerSide: "#1c1c1c"
    readonly property color text: "#f0f0f0"
    readonly property color muted: "#8c8c8c"
    readonly property color accent: "#34c77b"
    readonly property color selected: "#1b1b1b"
    readonly property color control: "#0a0a0a"
    readonly property color rowHover: "#0d0d0d"
    readonly property color tileHover: "#191919"

    // Couleurs de ressources
    readonly property color cpu: "#4da3ff"
    readonly property color memory: "#b57bee"
    readonly property color disk: "#3ecfd0"
    readonly property color network: "#f5b942"

    // Couleurs d'actions destructives
    readonly property color dangerDark: "#2a1515"
    readonly property color dangerRed: "#ff6b6b"
    readonly property color dangerBright: "#ff5a5a"
    readonly property color dangerText: "#1a0505"

    // Métriques
    readonly property int sidebarWidth: 156
    readonly property int tileHeight: 112
    readonly property int rowHeight: 44
    readonly property int statusBarHeight: 28
    readonly property int topBarHeight: 52

    // Polices
    readonly property string fontFamily: "sans-serif"
    readonly property int fontSizeNormal: 13
    readonly property int fontSizeSmall: 11
    readonly property int fontSizeHeader: 12
    readonly property int fontSizeValue: 20
    readonly property int fontSizeHero: 22
}
