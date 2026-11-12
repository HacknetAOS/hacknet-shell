import QtQuick
import "../singletons"

// TERMINAL region.
//
// The actual shell is a foot window placed here by the compositor; this panel
// only draws the caption and the 1px border, exactly like the game. It never
// takes input (empty region mask) so clicks and keystrokes reach the terminal.
Item {
    id: root

    Rectangle {
        id: caption
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: 14
        color: Theme.captionBar
        border.width: 1
        border.color: Theme.captionLine

        Text {
            anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
            text: "TERMINAL"
            color: Theme.captionFg
            font.family: Theme.mono
            font.pixelSize: Math.max(8, Theme.monoPx - 2)
            font.letterSpacing: 1
        }
        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: 1
            color: Theme.captionLine
        }
    }

    Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom
                  top: caption.bottom }
        color: "transparent"
        border.width: 1
        border.color: Theme.border
    }
}
