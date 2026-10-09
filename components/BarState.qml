pragma Singleton
import QtQuick

QtObject {
    property bool quickOpen: false
    property bool startOpen: false
    property bool hiddenOpen: false

    // only one flyout at a time
    onQuickOpenChanged:  if (quickOpen)  { startOpen = false; hiddenOpen = false; }
    onStartOpenChanged:  if (startOpen)  { quickOpen = false; hiddenOpen = false; }
    onHiddenOpenChanged: if (hiddenOpen) { quickOpen = false; startOpen = false; }

    // chevron x (window coords) for anchoring the hidden-tray popup
    property real hiddenX: 0
}
