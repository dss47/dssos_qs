pragma Singleton
import QtQuick
import common as C

// GENERATED PASS-THROUGH, not an independent palette.
//
// This file used to carry its own copy of every colour. Four Theme.qml
// singletons existed across dssos-apps and they had already drifted, so
// changing a colour meant finding which module happened to be loaded.
//
// common/Theme.qml is now the single source of truth. Every property is
// forwarded; only the few values listed in OVERRIDES below are kept local,
// because they are a deliberate layout choice of this app and not a palette
// decision. Add a new property to common/Theme.qml, not here.
QtObject {
    readonly property color bg: C.Theme.bg
    readonly property color sidebar: C.Theme.sidebar
    readonly property color side: C.Theme.side
    readonly property color list: C.Theme.list
    readonly property color status: C.Theme.status
    readonly property color rail: C.Theme.rail
    readonly property color card: C.Theme.card
    readonly property color cardHover: C.Theme.cardHover
    readonly property color divider: C.Theme.divider
    readonly property color dividerSide: C.Theme.dividerSide
    readonly property color edge: C.Theme.edge
    readonly property color text: C.Theme.text
    readonly property color muted: C.Theme.muted
    readonly property color accent: C.Theme.accent
    readonly property color accentDark: C.Theme.accentDark
    readonly property color selected: C.Theme.selected
    readonly property color hover: C.Theme.hover
    readonly property color control: C.Theme.control
    readonly property color controlHover: C.Theme.controlHover
    readonly property color rowHover: C.Theme.rowHover
    readonly property color tileHover: C.Theme.tileHover
    readonly property color danger: "#e5484d"   // Files' delete red is #e5484d, not common's #e05252
    readonly property color cpu: C.Theme.cpu
    readonly property color memory: C.Theme.memory
    readonly property color disk: C.Theme.disk
    readonly property color network: C.Theme.network
    readonly property color dangerDark: C.Theme.dangerDark
    readonly property color dangerRed: C.Theme.dangerRed
    readonly property color dangerBright: C.Theme.dangerBright
    readonly property color dangerText: C.Theme.dangerText
    readonly property int scrollWidth: C.Theme.scrollWidth
    readonly property color scrollThumb: C.Theme.scrollThumb
    readonly property color scrollThumbHover: C.Theme.scrollThumbHover
    readonly property int sidebarWidth: 200   // Files keeps a wider rail than Tasks
    readonly property int toolbarHeight: C.Theme.toolbarHeight
    readonly property int previewWidth: C.Theme.previewWidth
    readonly property int listHeaderHeight: C.Theme.listHeaderHeight
    readonly property int listRowHeight: C.Theme.listRowHeight
    readonly property int tileHeight: C.Theme.tileHeight
    readonly property int rowHeight: C.Theme.rowHeight
    readonly property int statusBarHeight: 26   // Files' status bar is 26px, not Tasks' 28
    readonly property int topBarHeight: C.Theme.topBarHeight
    readonly property string fontFamily: C.Theme.fontFamily
    readonly property int fontSizeNormal: C.Theme.fontSizeNormal
    readonly property int fontSizeSmall: C.Theme.fontSizeSmall
    readonly property int fontSizeHeader: C.Theme.fontSizeHeader
    readonly property int fontSizeTitle: C.Theme.fontSizeTitle
    readonly property int fontSizeValue: C.Theme.fontSizeValue
    readonly property int fontSizeHero: C.Theme.fontSizeHero
}
