import QtQuick
import "../singletons"

// Frame drawn around the DISPLAY region.
//
// The game labels the region with a bare caption above the window and outlines
// it with a 1px blue-grey border. The frame never takes input: clicks fall
// through to the application window hosted inside it.
Item {
    id: root

    readonly property var activeApp: {
        for (let i = 0; i < Daemon.stageWindows.length; ++i)
            if (Daemon.stageWindows[i].deck === Daemon.deckActive && Daemon.stageWindows[i].active)
                return Daemon.stageWindows[i];
        for (let i = 0; i < Daemon.stageWindows.length; ++i)
            if (Daemon.stageWindows[i].deck === Daemon.deckActive)
                return Daemon.stageWindows[i];
        return null;
    }

    // Caption bar: the game puts the region name inside a dark purple strip
    // edged with a brighter periwinkle line.
    readonly property int captionH: 14
    readonly property int titleH: 18

    Rectangle {
        id: caption
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: root.captionH
        color: Theme.captionBar
        border.width: 1
        border.color: Theme.captionLine

        Text {
            anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
            text: "DISPLAY"
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

    // Window chrome: the active window's title on a hairline strip, the way the
    // game labels each open window.
    Item {
        id: titleStrip
        anchors { left: parent.left; right: parent.right; top: caption.bottom }
        height: root.titleH
        visible: root.activeApp !== null

        Rectangle {
            anchors.fill: parent
            color: Theme.labelBg
        }
        Text {
            anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
            text: root.activeApp
                  ? (root.activeApp.title && root.activeApp.title.length
                     ? root.activeApp.title : (root.activeApp.class || "WINDOW"))
                  : "CONNECTED — " + Daemon.hostname
            color: Theme.labelFg
            font.family: Theme.mono
            font.pixelSize: Math.max(8, Theme.monoPx - 2)
            elide: Text.ElideRight
            width: parent.width - 16
        }
        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: 1
            color: "#9a9a9a"
        }
    }

    // Border encloses the application area, below the title strip. The frame is
    // input-transparent: the interactive connected screen is a separate panel
    // (see ScreenRoot) so its buttons receive clicks while an application's
    // window receives them when one is open.
    Rectangle {
        id: frame
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom
                  top: root.activeApp !== null ? titleStrip.bottom : caption.bottom }
        color: "transparent"
        border.width: 1
        border.color: Theme.border
    }
}
