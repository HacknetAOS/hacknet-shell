import QtQuick
import "../singletons"

// Hacknet's top strip: a hairline with a few flat icons, the system clock.
// No product logo, no navigation tabs, no home IP/location.
Item {
    id: root
    height: Geo.topbarHeight

    Rectangle {
        anchors.fill: parent
        color: Theme.topbarBg
    }
    Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 1
        color: Theme.topbarLine
    }

    // ---------------------------------------------------------------- left
    Row {
        id: leftIcons
        anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
        spacing: 12

        IconButton {
            kind: "close"
            onTriggered: Ui.toggleSession()
        }
        IconButton {
            kind: "gear"
            onTriggered: Ui.toggleSettings()
        }
        IconButton {
            kind: "search"
            onTriggered: Ui.toggleLauncher()
        }
        IconButton {
            kind: "server"
            onTriggered: Ui.run("hacknet-term", ["--app-id", "hacknet-stage",
                                                 "-e", "bash", "-lc", "fastfetch; exec bash"])
        }
        IconButton {
            kind: "folder"
            onTriggered: Ui.run("thunar")
        }
    }

    // ---------------------------------------------------------------- clock
    Text {
        anchors { left: leftIcons.right; leftMargin: 28; verticalCenter: parent.verticalCenter }
        // Hacknet prints the hour without a leading zero, in a large face.
        text: Qt.formatTime(root.now, "h:mm")
        color: "#b9a6ff"
        font.family: Theme.mono
        font.pixelSize: Math.max(11, Math.round(15 * Geo.scale))
        font.letterSpacing: 2
    }

    property var now: new Date()

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    // ---------------------------------------------------------------- right - NETMAP v1.7 and mail/history icons
    Text {
        anchors { right: parent.right; rightMargin: 28; verticalCenter: parent.verticalCenter }
        text: "NETMAP v1.7"
        color: Theme.captionFg
        font.family: Theme.mono
        font.pixelSize: Math.max(8, Theme.monoPx - 3)
        font.letterSpacing: 1
    }

    IconButton {
        id: mailBtn
        kind: "mail"
        anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
        onTriggered: Ui.toggleHistory()
    }

    Rectangle {
        visible: Notifs.notifications.length > 0
        anchors { top: mailBtn.top; right: mailBtn.right; topMargin: -1; rightMargin: -1 }
        width: 5
        height: 5
        radius: 2.5
        color: "#ff5555"
    }
}