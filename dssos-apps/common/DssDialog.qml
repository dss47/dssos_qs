import QtQuick
import QtQuick.Layouts
import "."

Item {
    id: root

    property bool open: false
    property string title: ""
    property string message: ""
    property string confirmText: "Confirm"
    property string cancelText: "Cancel"
    property string confirmVariant: "danger" // "danger" | "dangerDark" | "accent" | "card"
    property bool isDanger: confirmVariant.indexOf("danger") !== -1
    property int dialogWidth: 420
    property var _callback: null

    signal confirmed()
    signal cancelled()

    anchors.fill: parent
    visible: open
    z: 10000

    onVisibleChanged: {
        if (visible) {
            dialogBox.forceActiveFocus();
        }
    }

    function show(titleText, messageText, confirmBtnText, onConfirm, variant): void {
        root.title = titleText || "";
        root.message = messageText || "";
        root.confirmText = confirmBtnText || "Confirm";
        if (variant !== undefined) root.confirmVariant = variant;
        root._callback = onConfirm || null;
        root.open = true;
        dialogBox.forceActiveFocus();
    }

    function accept(): void {
        root.open = false;
        var cb = root._callback;
        root._callback = null;
        root.confirmed();
        if (cb && typeof cb === "function") {
            cb();
        }
    }

    function reject(): void {
        root.open = false;
        root._callback = null;
        root.cancelled();
    }

    // Backdrop semi-transparent
    Rectangle {
        anchors.fill: parent
        color: "#aa000000"

        MouseArea {
            anchors.fill: parent
            onClicked: root.reject()
        }
    }

    // Boîte de dialogue
    Rectangle {
        id: dialogBox
        focus: true
        anchors.centerIn: parent
        width: root.dialogWidth
        implicitHeight: dialogLayout.implicitHeight + 36
        color: Theme.card
        border.width: 1
        border.color: root.isDanger ? Theme.danger : Theme.divider

        // Consomme les clics à l'intérieur pour éviter la fermeture
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        ColumnLayout {
            id: dialogLayout
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            Text {
                id: titleLabel
                text: root.title
                color: Theme.text
                font.pixelSize: Theme.fontSizeTitle
                font.family: Theme.fontFamily
                font.weight: Font.DemiBold
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            Text {
                id: messageLabel
                text: root.message
                color: Theme.muted
                font.pixelSize: Theme.fontSizeSmall
                font.family: Theme.fontFamily
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                visible: text !== ""
            }

            Item {
                Layout.preferredHeight: 4
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignRight
                spacing: 10

                Item {
                    Layout.fillWidth: true
                }

                DssButton {
                    text: root.cancelText
                    variant: "ghost"
                    onClicked: root.reject()
                }

                DssButton {
                    text: root.confirmText
                    variant: root.confirmVariant
                    onClicked: root.accept()
                }
            }
        }

        // Raccourcis clavier au niveau du dialogue
        Keys.onEscapePressed: (event) => {
            root.reject();
            event.accepted = true;
        }

        Keys.onReturnPressed: (event) => {
            root.accept();
            event.accepted = true;
        }

        Keys.onEnterPressed: (event) => {
            root.accept();
            event.accepted = true;
        }
    }
}
