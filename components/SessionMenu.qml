import QtQuick
import "../singletons"

// Session menu: the game's own power options, nothing more.
Rectangle {
    id: root
    implicitWidth: 380
    implicitHeight: 400  // Increased height to show all 5 buttons

    color: "#0b0d13"
    border.width: 1
    border.color: Theme.border

    Text {
        id: caption
        anchors { left: parent.left; top: parent.top; leftMargin: 10; topMargin: 6 }
        text: "SESSION"
        color: Theme.dim
        font.family: Theme.mono
        font.pixelSize: Math.max(8, Theme.monoPx - 2)
        font.letterSpacing: 1
    }

    Rectangle {
        anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 24 }
        height: 1
        color: Theme.borderDim
    }

    Column {
        anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 40
                  leftMargin: 18; rightMargin: 18 }
        spacing: 8  // Reduced spacing to fit all 5 buttons

        Text {
            text: Daemon.username + "@" + Daemon.hostname
            color: "#b9bcc4"
            font.family: Theme.mono
            font.pixelSize: Theme.monoPx
        }

        Rectangle { width: parent.width; height: 1; color: Theme.borderDim }

        LauncherButton {
            width: parent.width
            label: "LOCK"
            onTriggered: Ui.lockSession()
        }
        LauncherButton {
            width: parent.width
            label: "REBOOT"
            onTriggered: { Ui.closeAll(); Daemon.run("sudo", ["-n", "systemctl", "reboot"]); }
        }
        LauncherButton {
            width: parent.width
            label: "SHUT DOWN"
            accentColor: Theme.alert
            onTriggered: { Ui.closeAll(); Daemon.run("sudo", ["-n", "systemctl", "poweroff"]); }
        }
        LauncherButton {
            width: parent.width
            label: "LOG OUT"
            onTriggered: { Ui.closeAll(); Daemon.run("loginctl", ["terminate-user", Daemon.username]); }
        }
        // Disconnect button - only shown when connected to a remote session
        // For now, not shown since we don't have remote session support yet
        // When implemented, would show: 
        // LauncherButton {
        //     width: parent.width
        //     label: "DISCONNECT"
        //     onTriggered: { Ui.closeAll(); Daemon.disconnectRemote(); }
        // }
        LauncherButton {
            width: parent.width
            label: "CANCEL"
            onTriggered: Ui.closeAll()
        }
    }
}