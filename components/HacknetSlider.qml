import QtQuick
import "../singletons"

Item {
    id: root
    property string label: ""
    property real value: 0.0
    property string displayValue: Math.round(root.value * 100) + "%"
    property bool enabled: true
    signal valueChangedByUser(real newValue)

    implicitWidth: 320
    implicitHeight: 46

    Item {
        id: header
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: 18

        Text {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            text: root.label
            color: "#9aa0ab"
            font.family: Theme.mono
            font.pixelSize: Theme.monoPx
            font.letterSpacing: 1
        }

        Text {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            text: "[ " + root.displayValue + " ]"
            color: Theme.accent
            font.family: Theme.mono
            font.pixelSize: Math.max(8, Theme.monoPx - 1)
            font.bold: true
        }
    }

    Rectangle {
        id: track
        anchors { left: parent.left; right: parent.right; top: header.bottom; topMargin: 6 }
        height: 16
        color: "#0a0c14"
        border.width: 1
        border.color: Theme.borderDim

        Rectangle {
            id: fill
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom; margins: 1 }
            width: Math.max(0, Math.min(track.width - 2, (track.width - 2) * root.value))
            color: mouseArea.containsMouse ? Theme.accent : Theme.highlight
        }

        Rectangle {
            id: thumb
            x: Math.max(0, Math.min(track.width - width, fill.width - width / 2))
            anchors.verticalCenter: parent.verticalCenter
            width: 8
            height: track.height + 4
            color: "#ffffff"
            border.width: 1
            border.color: Theme.accent
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            anchors.margins: -4
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            function updateFromMouse(mouseX) {
                const ratio = Math.max(0.0, Math.min(1.0, (mouseX - 4) / track.width));
                root.valueChangedByUser(ratio);
            }

            onPressed: (mouse) => updateFromMouse(mouse.x)
            onPositionChanged: (mouse) => {
                if (pressed) updateFromMouse(mouse.x);
            }
        }
    }
}
