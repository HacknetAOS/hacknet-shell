import QtQuick
import "../singletons"

// Round status indicator used in the NETMAP strip: a green check for a healthy
// link and a red power button, both ringed the way Hacknet draws them.
Item {
    id: root

    property string kind: "ok"      // "ok" | "power"
    signal triggered()

    implicitWidth: Math.round(26 * Geo.scale)
    implicitHeight: implicitWidth

    readonly property color ringColor: kind === "power" ? "#d0342a" : "#3f9a4f"

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: "#090a0c"
        border.width: 2
        border.color: root.ringColor
        opacity: 0.95
    }

    Text {
        anchors.centerIn: parent
        text: root.kind === "power" ? "⏻" : "✓"
        color: root.ringColor
        font.family: Theme.mono
        font.pixelSize: Math.round(root.width * 0.5)
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.triggered()
    }
}
