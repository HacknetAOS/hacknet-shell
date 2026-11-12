import QtQuick
import "../singletons"

// Message history, opened by the envelope in the top strip.
// Same chrome as the other panels: purple caption bar, periwinkle border,
// flat rows. No rounded corners or glow.
Rectangle {
    id: root
    implicitWidth: 560
    implicitHeight: 440

    color: "#0a0b0d"
    border.width: 1
    border.color: Theme.border

    Rectangle {
        id: caption
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: 20
        color: Theme.captionBar
        border.width: 1
        border.color: Theme.captionLine

        Text {
            anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
            text: "MESSAGES"
            color: Theme.captionFg
            font.family: Theme.mono
            font.pixelSize: Math.max(8, Theme.monoPx - 2)
            font.letterSpacing: 1
        }
    }

    Text {
        anchors.centerIn: parent
        text: "NO MESSAGES"
        visible: Notifs.notifications.length === 0
        color: Theme.dim
        font.family: Theme.mono
        font.pixelSize: Theme.monoPx
        font.letterSpacing: 1
    }

    ListView {
        id: list
        anchors { left: parent.left; leftMargin: 8; right: parent.right; rightMargin: 8
                  top: caption.bottom; topMargin: 8; bottom: clearRow.top; bottomMargin: 8 }
        spacing: 4
        clip: true
        model: Notifs.notifications
        // The model is a plain JS array of objects, so delegates read the
        // fields from `modelData` (not `model.*`, which only exists for
        // ListModel roles — that was why every row rendered empty).
        delegate: Rectangle {
            width: list.width
            height: Math.max(58, inner.implicitHeight + 12)
            color: "#141418"
            border.width: 1
            border.color: "#3a3560"

            Rectangle {
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                width: 3
                color: (modelData.urgency === "critical") ? Theme.alert : Theme.accentStrip
            }

            Column {
                id: inner
                anchors { left: parent.left; leftMargin: 12; right: parent.right; rightMargin: 10
                          top: parent.top; topMargin: 6 }
                spacing: 2

                Text {
                    width: parent.width
                    text: modelData.app || ""
                    color: Theme.dim
                    font.family: Theme.mono
                    font.pixelSize: Math.max(7, Theme.monoPx - 3)
                    elide: Text.ElideRight
                    visible: (modelData.app || "") !== ""
                }
                Text {
                    width: parent.width
                    text: modelData.title || ""
                    color: "#dcdce2"
                    font.family: Theme.mono
                    font.pixelSize: Theme.monoPx
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    text: modelData.body || ""
                    color: "#9a94c8"
                    font.family: Theme.mono
                    font.pixelSize: Math.max(8, Theme.monoPx - 2)
                    wrapMode: Text.WrapAnywhere
                    maximumLineCount: 2
                    visible: (modelData.body || "") !== ""
                }
                Text {
                    text: (modelData.timeText || "")
                          + ((modelData.urgency === "critical") ? "  CRITICAL" : "")
                    color: Theme.dim
                    font.family: Theme.mono
                    font.pixelSize: Math.max(7, Theme.monoPx - 3)
                }
            }
        }
    }

    Row {
        id: clearRow
        anchors { right: parent.right; bottom: parent.bottom; rightMargin: 8; bottomMargin: 8 }
        spacing: 8

        LauncherButton { label: "CLEAR ALL"; onTriggered: Notifs.clear() }
        LauncherButton { label: "CLOSE"; onTriggered: Ui.closeAll() }
    }
}
