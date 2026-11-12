import QtQuick
import Quickshell.Io
import "../singletons"

Rectangle {
    id: root
    color: "#07070b"

    property bool checking: false
    property string errorText: ""
    property var now: new Date()

    Timer {
        interval: 1000
        running: Ui.locked
        repeat: true
        onTriggered: root.now = new Date()
    }

    function attemptUnlock() {
        if (root.checking) return;
        root.checking = true;
        root.errorText = "";
        authProc.pendingPassword = passInput.text;
        authProc.running = true;
    }

    Process {
        id: authProc
        property string pendingPassword: ""
        command: ["sh", "-c", "printf '%s\\0' \"$1\" | /usr/bin/unix_chkpwd \"$2\" nullok", "sh", pendingPassword, Daemon.username]
        onExited: (code, _status) => {
            root.checking = false;
            if (code === 0) {
                passInput.text = "";
                root.errorText = "";
                Ui.unlockSession();
            } else {
                passInput.text = "";
                root.errorText = "ACCESS DENIED — INVALID CREDENTIALS";
                passInput.forceActiveFocus();
            }
        }
    }

    Connections {
        target: Ui
        function onLockedChanged() {
            if (Ui.locked) {
                passInput.text = "";
                root.errorText = "";
                root.now = new Date();
                passInput.forceActiveFocus();
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: passInput.forceActiveFocus()
    }

    Rectangle {
        id: card
        width: 440
        height: 280
        anchors.centerIn: parent
        color: "#0b0d13"
        border.width: 1
        border.color: Theme.border

        Rectangle {
            id: captionStrip
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: 24
            color: Theme.captionBar
            border.width: 1
            border.color: Theme.captionLine

            Text {
                anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                text: "TERMINAL LOCK // AUTHENTICATION REQUIRED"
                color: Theme.captionFg
                font.family: Theme.mono
                font.pixelSize: Math.max(8, Theme.monoPx - 2)
                font.letterSpacing: 1
            }
        }

        Column {
            anchors {
                left: parent.left; right: parent.right
                top: captionStrip.bottom; bottom: parent.bottom
                margins: 22
            }
            spacing: 14

            Text {
                text: Qt.formatTime(root.now, "hh:mm:ss")
                color: Theme.accent
                font.family: Theme.mono
                font.pixelSize: Math.round(Theme.monoPx * 2.2)
                font.bold: true
            }

            Text {
                text: "Locked session: " + Daemon.username + "@" + Daemon.hostname
                color: "#b9bcc4"
                font.family: Theme.mono
                font.pixelSize: Theme.monoPx
            }

            Rectangle {
                width: parent.width
                height: 36
                color: "#06070b"
                border.width: 1
                border.color: passInput.activeFocus ? Theme.accent : Theme.borderDim

                TextInput {
                    id: passInput
                    anchors {
                        fill: parent
                        leftMargin: 10
                        rightMargin: 10
                    }
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    passwordCharacter: "*"
                    color: "#ffffff"
                    font.family: Theme.mono
                    font.pixelSize: Theme.monoPx
                    focus: Ui.locked
                    Keys.onReturnPressed: root.attemptUnlock()
                    Keys.onEnterPressed: root.attemptUnlock()
                }

                Text {
                    anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                    visible: passInput.text.length === 0
                    text: "Enter password..."
                    color: Theme.dim
                    font.family: Theme.mono
                    font.pixelSize: Theme.monoPx
                }
            }

            Text {
                text: root.errorText.length > 0
                      ? root.errorText
                      : (root.checking ? "Verifying credentials..." : "Press Enter or click UNLOCK to resume session")
                color: root.errorText.length > 0 ? Theme.alert : Theme.dim
                font.family: Theme.mono
                font.pixelSize: Math.max(9, Theme.monoPx - 2)
            }

            LauncherButton {
                width: parent.width
                label: root.checking ? "VERIFYING..." : "UNLOCK"
                onTriggered: root.attemptUnlock()
            }
        }
    }
}
