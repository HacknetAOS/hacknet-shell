import QtQuick
import "../singletons"

// Hacknet's list button: flat near-black fill, 1px grey outline, light grey
// text, and a coloured strip on the left edge when active/hovered.
Rectangle {
    id: root

    property string label: ""
    property bool active: false
    property color accentColor: Theme.accent
    signal triggered()

    implicitWidth: Math.max(120, labelText.implicitWidth + 26)
    implicitHeight: Math.round(30 * Geo.scale)

    color: mouse.containsMouse || active ? Theme.buttonHover : Theme.buttonBg
    border.width: 1
    border.color: mouse.containsMouse || active ? Theme.accentStrip : Theme.buttonBorder
    radius: 0

    // Left accent strip (the game marks the focused row this way).
    Rectangle {
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        width: 3
        // Accent rows (e.g. Disconnect) keep their strip visible at rest, as in
        // the game; neutral rows only show it on hover/focus.
        visible: root.active || mouse.containsMouse || root.accentColor !== Theme.accent
        color: root.accentColor === Theme.accent ? Theme.accentStrip
               : (root.accentColor === Theme.alert ? Theme.alertStrip : root.accentColor)
    }

    Text {
        id: labelText
        anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
        text: root.label
        color: root.active ? "#ffffff" : "#dcdce2"
        font.family: Theme.mono
        font.pixelSize: Theme.monoPx
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.triggered()
    }
}
