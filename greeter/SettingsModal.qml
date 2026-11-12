import QtQuick

Item {
    id: modalRoot
    anchors.fill: parent

    signal backClicked()

    // Semi-transparent backdrop
    Rectangle {
        anchors.fill: parent
        color: "#050b10"
        opacity: 0.85

        MouseArea {
            anchors.fill: parent
            // block clicks through
        }
    }

    // Modal Box
    Rectangle {
        width: 520
        height: 380
        anchors.centerIn: parent
        color: "#08121a"
        border.width: 1
        border.color: "#18384d"

        Column {
            anchors.fill: parent
            anchors.margins: 28
            spacing: 24

            Text {
                text: "- SYSTEM SETTINGS -"
                color: "#00b4e6"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 18
                font.bold: true
                font.letterSpacing: 2
            }

            // Setting 1: UI Audio Feedback
            Row {
                width: parent.width
                spacing: 20

                Text {
                    width: 200
                    text: "AUDIO FEEDBACK :"
                    color: "#a0c0d0"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    anchors.verticalCenter: parent.verticalCenter
                }

                Rectangle {
                    width: 100
                    height: 32
                    color: soundMouse.containsMouse ? "#0a2636" : "#091720"
                    border.width: 1
                    border.color: soundState ? "#5fdc53" : "#304856"
                    property bool soundState: true

                    Text {
                        anchors.centerIn: parent
                        text: parent.soundState ? "ENABLED" : "MUTED"
                        color: parent.soundState ? "#5fdc53" : "#708896"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        font.bold: true
                    }

                    MouseArea {
                        id: soundMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: parent.soundState = !parent.soundState
                    }
                }
            }

            // Setting 2: Display Scaling
            Row {
                width: parent.width
                spacing: 20

                Text {
                    width: 200
                    text: "DISPLAY SCALING :"
                    color: "#a0c0d0"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    anchors.verticalCenter: parent.verticalCenter
                }

                Rectangle {
                    width: 100
                    height: 32
                    color: "#091720"
                    border.width: 1
                    border.color: "#00b4e6"

                    Text {
                        anchors.centerIn: parent
                        text: "100% (1.0x)"
                        color: "#ffffff"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        font.bold: true
                    }
                }
            }

            // Setting 3: Keyboard Layout
            Row {
                width: parent.width
                spacing: 20

                Text {
                    width: 200
                    text: "KEYBOARD LAYOUT :"
                    color: "#a0c0d0"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    anchors.verticalCenter: parent.verticalCenter
                }

                Rectangle {
                    width: 100
                    height: 32
                    color: "#091720"
                    border.width: 1
                    border.color: "#1a3b4f"

                    Text {
                        anchors.centerIn: parent
                        text: "us (QWERTY)"
                        color: "#ffffff"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                    }
                }
            }

            Item { height: 10; width: 1 }

            // Back button
            Rectangle {
                width: 140
                height: 38
                anchors.right: parent.right
                color: backMouse.containsMouse ? "#0a2636" : "#091720"
                border.width: 1
                border.color: backMouse.containsMouse ? "#00b4e6" : "#1a3b4f"

                Text {
                    anchors.centerIn: parent
                    text: "[ RETURN ]"
                    color: backMouse.containsMouse ? "#ffffff" : "#a0c0d0"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                    font.bold: true
                    font.letterSpacing: 1.2
                }

                MouseArea {
                    id: backMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: modalRoot.backClicked()
                }
            }
        }
    }
}
