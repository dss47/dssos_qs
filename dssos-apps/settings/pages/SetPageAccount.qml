import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import common

// Account > Your account
//
// Click the avatar to open the picture picker -- there is no separate Browse
// section. Three real capabilities, all via dssos-account-ctl:
//   avatar        ~/.local/share/dssos/avatars/<user>.png  (no privilege needed)
//   username      read-only (renaming a live uid is a different operation)
//   display name  GECOS field, needs root
//   password      chpasswd, needs root, password travels on stdin only
ColumnLayout {
    id: root
    Layout.fillWidth: true
    spacing: 0

    property var account: ({})
    property var candidates: []
    property string statusText: ""
    property bool statusIsError: false
    property string pendingOp: ""

    readonly property var self_: (account && account.user) ? account.user : ""
    property bool pickerOpen: false

    // ---------------------------------------------------------------- inputs

    // One consistent field style for every value in this page.
    component AccountInput: Rectangle {
        id: box
        property alias text: field.text
        property bool secret: false
        property alias input: field
        // Forward the TextInput signal so callers can write `onAccepted:`.
        signal accepted()
        implicitWidth: 250
        implicitHeight: 34
        color: SettingsTheme.control
        border.width: 1
        border.color: field.activeFocus ? SettingsTheme.accent : SettingsTheme.edge

        TextInput {
            id: field
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            verticalAlignment: TextInput.AlignVCenter
            color: SettingsTheme.text
            font.pixelSize: 13
            selectByMouse: true
            echoMode: box.secret ? TextInput.Password : TextInput.Normal
            clip: true
            onAccepted: box.accepted()
        }
    }

    // ---------------------------------------------------------------- helpers

    function say(msg, isError) {
        // Set the flag BEFORE the text so onStatusTextChanged handlers never
        // observe the previous message's severity.
        statusIsError = isError === true;
        statusText = "";
        statusText = msg;
        if (!isError) statusReset.restart();
    }

    function reload() {
        getProc.running = true;
        avatarsProc.running = true;
    }

    function setDisplayName(v) {
        pendingOp = "set-displayname";
        applyProc.command = ["pkexec", "--disable-internal-agent",
                             "/usr/local/bin/dssos-account-ctl", "apply"];
        applyProc.stdinEnabled = true;
        // Deferred: a Process started in the same tick as its
        // `command` assignment runs the PREVIOUS command.
        Qt.callLater(function () { applyProc.running = true; });
        applyProc.write(JSON.stringify({ op: "set-displayname", user: root.self_,
                                         displayName: v }) + "\n");
    }

    function setPassword(pw) {
        pendingOp = "set-password";
        applyProc.command = ["pkexec", "--disable-internal-agent",
                             "/usr/local/bin/dssos-account-ctl", "apply"];
        applyProc.stdinEnabled = true;
        // Deferred: a Process started in the same tick as its
        // `command` assignment runs the PREVIOUS command.
        Qt.callLater(function () { applyProc.running = true; });
        applyProc.write(JSON.stringify({ op: "set-password", user: root.self_,
                                         password: pw }) + "\n");
        pw1.text = "";
        pw2.text = "";
    }

    // An image path is not a secret and the avatar lives in the user's own
    // home, so this needs no privilege prompt and no stdin pipe.
    function setAvatar(sourcePath) {
        avatarProc.command = ["dssos-account-ctl", "set-avatar", root.self_,
                              sourcePath];
        // Reassigning `command` and setting `running` in the same tick makes
        // Quickshell run the OLD command; start on the next tick instead.
        Qt.callLater(function () { avatarProc.running = true; });
    }

    function pickFrom(path) {
        if (staging.source === path) return;
        staging.source = path;
    }

    Timer {
        id: statusReset
        interval: 4000
        onTriggered: root.statusText = ""
    }

    // --------------------------------------------------------------- processes

    Process {
        id: getProc
        command: ["dssos-account-ctl", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text.trim());
                    root.account = d;
                    if (!avatarImage.source && d.avatar)
                        avatarImage.source = d.avatar;
                } catch (e) {
                    root.say("Could not read account details", true);
                }
            }
        }
    }

    Process {
        id: avatarsProc
        command: ["dssos-account-ctl", "avatars"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.candidates = JSON.parse(text.trim());
                } catch (e) {
                    root.candidates = [];
                }
            }
        }
    }

    Process {
        id: avatarProc
        command: ["dssos-account-ctl", "set-avatar", "", ""]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text.trim());
                    root.account = d;
                    avatarImage.source = "";
                    avatarImage.source = d.avatar;
                    root.pickerOpen = false;
                    root.say("Picture updated");
                } catch (e) {
                    root.say("Could not set that picture", true);
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: (t) => {
                if (t && t.trim().length > 0)
                    root.say(t.trim().split("\n").pop(), true);
            }
        }
    }

    Process {
        id: applyProc
        stdinEnabled: true
        command: ["pkexec", "--disable-internal-agent",
                  "/usr/local/bin/dssos-account-ctl", "apply"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text.trim());
                    root.account = d;
                    root.say(root.pendingOp === "set-password"
                             ? "Password changed" : "Name updated");
                } catch (e) {
                    root.say("Update failed", true);
                }
                root.pendingOp = "";
            }
        }
        stderr: StdioCollector {
            onStreamFinished: (t) => {
                if (t && t.trim().length > 0)
                    root.say(t.trim().split("\n").pop(), true);
            }
        }
    }

    // Offscreen renderer: crops the chosen picture square and writes a 256x256
    // PNG using core Qt Quick (grabToImage/saveToFile). No ImageMagick needed.
    Item {
        id: staging
        visible: false
        width: 256
        height: 256
        property string source: ""

        Image {
            id: stageImage
            anchors.fill: parent
            source: parent.source
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            onStatusChanged: {
                if (status !== Image.Ready) return;
                stageImage.grabToImage(function (result) {
                    const tmp = "/tmp/dssos-avatar-staged.png";
                    if (result.saveToFile(tmp)) {
                        root.setAvatar(tmp);
                    } else {
                        root.say("Could not process that image", true);
                    }
                }, Qt.size(256, 256));
            }
        }
    }

    Component.onCompleted: reload()

    // -------------------------------------------------------------------- UI

    Text {
        text: "Your account"
        font.pixelSize: 24
        font.weight: Font.DemiBold
        color: SettingsTheme.text
        Layout.bottomMargin: 18
    }

    SetCard {
        Layout.bottomMargin: root.pickerOpen ? 12 : 18

        // Avatar + identity. Clicking the circle opens the picker.
        SetRow {
            label: root.account.displayName || root.self_ || "Account"
            hint: root.account.isAdmin === true
                  ? "Administrator \\u00b7 member of wheel \\u00b7 click the picture to change it"
                  : "Standard account \\u00b7 click the picture to change it"

            Rectangle {
                Layout.preferredWidth: 72
                Layout.preferredHeight: 72
                // A rounded Rectangle with clip:true clips its children to the
                // rounded shape, which gives a circular avatar without needing
                // QtQuick.Effects.
                radius: width / 2
                clip: true
                color: SettingsTheme.control
                border.width: pickerOpen ? 2 : 1
                border.color: pickerOpen ? SettingsTheme.accent
                                         : SettingsTheme.edge

                Image {
                    id: avatarImage
                    anchors.fill: parent
                    source: root.account.avatar || ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: status === Image.Ready
                }

                Text {
                    anchors.centerIn: parent
                    visible: avatarImage.status !== Image.Ready
                    text: (root.self_ || "?").charAt(0).toUpperCase()
                    font.pixelSize: 28
                    color: SettingsTheme.muted
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.candidates.length === 0) {
                            root.say("No pictures found. Put some in ~/Pictures.", true);
                            return;
                        }
                        root.pickerOpen = !root.pickerOpen;
                        if (root.pickerOpen) avatarsProc.running = true;
                    }
                }
            }
        }

        SetRow {
            label: "Display name"
            hint: "Shown in menus and on the lock screen"

            AccountInput {
                id: nameInput
                text: root.account.displayName || ""
                onAccepted: {
                    const v = text.trim();
                    if (v !== (root.account.displayName || "")) root.setDisplayName(v);
                }
            }
        }

        SetRow {
            label: "Username"
            hint: "Your system login name"

            Text {
                text: root.self_
                font.pixelSize: 13
                color: SettingsTheme.muted
            }
        }

        SetRow {
            label: "New password"
            hint: "At least 6 characters"

            AccountInput {
                id: pw1
                secret: true
            }
        }

        SetRow {
            label: "Confirm password"
            isLast: true

            RowLayout {
                spacing: 10
                AccountInput {
                    id: pw2
                    secret: true
                    onAccepted: commitPassword()
                }
                DssButton {
                    text: "Change"
                    variant: "accent"
                    enabled: pw1.text.length >= 6 && pw2.text.length >= 6
                             && pw1.text === pw2.text
                    onClicked: commitPassword()
                }
            }
        }
    }

    // The picker is a panel, not a permanent section: it only exists while the
    // avatar has been clicked.
    SetCard {
        id: pickerCard
        visible: root.pickerOpen
        Layout.bottomMargin: 14

        Text {
            text: "Choose a picture"
            font.pixelSize: 13
            font.weight: Font.DemiBold
            color: SettingsTheme.muted
            Layout.leftMargin: 16
            Layout.topMargin: 14
            Layout.bottomMargin: 10
        }

        GridView {
            id: picker
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.bottomMargin: 14
            Layout.preferredHeight: 176
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: root.candidates
            cellWidth: 92
            cellHeight: 92

            delegate: Rectangle {
                width: 92
                height: 92
                color: tileHover.containsMouse ? SettingsTheme.hover
                                               : SettingsTheme.control
                border.width: 1
                border.color: tileHover.containsMouse ? SettingsTheme.accent
                                                     : SettingsTheme.edge

                Image {
                    anchors.fill: parent
                    anchors.margins: 5
                    source: modelData.path
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize.width: 160
                }

                MouseArea {
                    id: tileHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.pickFrom(modelData.path)
                }
            }
        }
    }

    function commitPassword() {
        if (pw1.text.length < 6) {
            root.say("Password must be at least 6 characters", true);
            return;
        }
        if (pw1.text !== pw2.text) {
            root.say("The two passwords do not match", true);
            return;
        }
        root.setPassword(pw1.text);
    }

    Text {
        Layout.topMargin: 2
        visible: root.statusText.length > 0
        text: root.statusText
        font.pixelSize: 13
        color: root.statusIsError ? SettingsTheme.danger : SettingsTheme.accent
    }
}
