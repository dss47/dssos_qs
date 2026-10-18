pragma Singleton
import QtQuick
import common

QtObject {
    readonly property color bg: Theme.bg
    readonly property color rail: Theme.rail
    readonly property color list: Theme.list
    readonly property color card: Theme.card
    readonly property color divider: Theme.divider
    readonly property color edge: Theme.edge
    readonly property color text: Theme.text
    readonly property color muted: Theme.muted
    readonly property color accent: Theme.accent
    readonly property color accentDark: Theme.accentDark
    readonly property color selected: Theme.selected
    readonly property color hover: Theme.hover
    readonly property color control: Theme.control
    readonly property color controlHover: Theme.controlHover
    readonly property color danger: Theme.danger
}
