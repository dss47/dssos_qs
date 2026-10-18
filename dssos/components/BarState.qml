pragma Singleton
import QtQuick

QtObject {
    property bool quickOpen: false
    property bool startOpen: false
    property bool hiddenOpen: false
    property string quickTarget: ""

    // only one flyout at a time
    onQuickOpenChanged: {
        if (quickOpen) {
            startOpen = false;
            hiddenOpen = false;
            if (quickTarget === "") quickTarget = "status";
        } else {
            quickTarget = "";
        }
    }
    onStartOpenChanged:  if (startOpen)  { quickOpen = false; hiddenOpen = false; quickTarget = ""; }
    onHiddenOpenChanged: if (hiddenOpen) { quickOpen = false; startOpen = false; quickTarget = ""; }

    // chevron x (window coords) for anchoring the hidden-tray popup
    property real hiddenX: 0
}
