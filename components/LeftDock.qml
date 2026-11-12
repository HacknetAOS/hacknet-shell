import QtQuick
import "../singletons"

// Left gutter, top block: the "RAM" caption strip and the memory readout.
//
// The rest of the column belongs to dock terminal windows (hacknet-dock-N)
// placed by the daemon, and the audio analyser lives in its own panel flush
// with the bottom-left (see the hacknet-visualizer layer surface).
Item {
    id: root
    width: Geo.gutterWidth
    visible: !Daemon.gutterHidden

    readonly property var mem: Daemon.memory

    function mb(kib) {
        return Math.round((kib || 0) / 1024);
    }

    // Caption strip, same chrome as the other panels.
    Rectangle {
        id: captionBar
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: 14
        color: Theme.captionBar
        border.width: 1
        border.color: Theme.captionLine

        Text {
            anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
            text: "RAM"
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

    Text {
        id: ramText
        anchors { left: parent.left; leftMargin: 8; top: captionBar.bottom; topMargin: 6 }
        text: "USED RAM:" + root.mb(root.mem && root.mem.used) + "Mb / "
              + root.mb(root.mem && root.mem.total) + "Mb"
        color: Theme.captionFg
        font.family: Theme.mono
        font.pixelSize: Math.max(9, Theme.monoPx - 1)
    }

    Rectangle {
        id: ramBarBg
        anchors { left: parent.left; right: parent.right; top: ramText.bottom; leftMargin: 8; rightMargin: 8; topMargin: 4 }
        height: 2
        color: Theme.borderDim
        Rectangle {
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            width: Math.min(parent.width, Math.max(1, parent.width * ((root.mem && root.mem.pct) || 0) / 100))
            color: ((root.mem && root.mem.pct) || 0) > 85 ? "#ff5555" : Theme.accent
        }
    }
}
