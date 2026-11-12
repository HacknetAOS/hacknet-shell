import QtQuick
import "../singletons"

// Notification popup, top-right, shown when a notification arrives.
//
// Same chrome as the rest of the shell: near-black panel, hairline border,
// caption strip with the app name, monospace body. Text colours are explicit
// (not theme "dim") so the message is always legible on the dark panel.
Rectangle {
    id: root

    implicitWidth: 360
    implicitHeight: 108
    color: "#0b0d13"
    border.width: 1
    border.color: Theme.captionLine

    // Accept data from Notifs.popupData. NOTE: named `notif`, NOT `data` —
    // `data` is Item's built-in default property (the child list).
    property var notif: null
    readonly property string title: notif ? (notif.title || "") : ""
    readonly property string body: notif ? (notif.body || "") : ""
    readonly property string app: notif ? (notif.app || "") : ""

    Timer {
        interval: 6000
        repeat: false
        running: root.notif !== null
        onTriggered: Notifs.popupOpen = false
    }

    // Caption strip: app name, like a Hacknet window title.
    Rectangle {
        id: caption
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: 18
        color: Theme.captionBar
        border.width: 1
        border.color: Theme.captionLine

        Text {
            anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
            width: parent.width - 12
            text: root.app !== "" ? root.app : "NOTIFICATION"
            color: Theme.captionFg
            font.family: Theme.mono
            font.pixelSize: Math.max(8, Theme.monoPx - 3)
            elide: Text.ElideRight
        }
    }

    Column {
        anchors { left: parent.left; right: parent.right; top: caption.bottom
                  leftMargin: 10; rightMargin: 10; topMargin: 8 }
        spacing: 3

        Text {
            width: parent.width
            text: root.title
            color: "#e8e6f4"
            font.family: Theme.mono
            font.pixelSize: Math.max(10, Theme.monoPx)
            elide: Text.ElideRight
            visible: root.title !== ""
        }
        Text {
            width: parent.width
            text: root.body
            color: "#b9b6cc"
            font.family: Theme.mono
            font.pixelSize: Math.max(9, Theme.monoPx - 1)
            wrapMode: Text.WrapAnywhere
            maximumLineCount: 3
            elide: Text.ElideRight
            visible: root.body !== ""
        }
    }
}
