import QtQuick

Item {
    id: btnRoot
    property string text: ""
    property color accentColor: "#8fa4b8"
    property color normalBgColor: "#181b20"
    property color hoverBgColor: "#222730"
    property color normalBorderColor: "#3e444d"
    property color hoverBorderColor: "#8fa4b8"
    property color normalTextColor: "#d8e2ea"
    property color hoverTextColor: "#ffffff"
    property int tabWidth: 12

    signal clicked()

    implicitWidth: 450
    implicitHeight: 36

    Rectangle {
        id: bgRect
        anchors.fill: parent
        color: mouseArea.containsMouse ? btnRoot.hoverBgColor : btnRoot.normalBgColor
        border.width: 1
        border.color: mouseArea.containsMouse ? btnRoot.hoverBorderColor : btnRoot.normalBorderColor

        // Accent tab on the left edge (matches in-game design)
        Rectangle {
            id: accentTab
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: btnRoot.tabWidth
            color: btnRoot.accentColor
        }

        // Button label
        Text {
            anchors.left: parent.left
            anchors.leftMargin: btnRoot.tabWidth + 14
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: btnRoot.text
            color: mouseArea.containsMouse ? btnRoot.hoverTextColor : btnRoot.normalTextColor
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 14
            font.bold: false
            font.letterSpacing: 0.8
            elide: Text.ElideRight
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btnRoot.clicked()
    }
}
