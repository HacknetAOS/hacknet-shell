import QtQuick
import Quickshell.Io

Item {
    id: powerRoot
    anchors.fill: parent

    signal cancelClicked()

    Process {
        id: powerProc
        running: false
    }

    function execPower(cmd) {
        powerProc.command = ["loginctl", cmd];
        powerProc.running = true;
    }

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
        width: 480
        height: 280
        anchors.centerIn: parent
        color: "#08121a"
        border.width: 1
        border.color: "#301518"

        Column {
            anchors.fill: parent
            anchors.margins: 26
            spacing: 20

            Text {
                text: "- SYSTEM POWER TERMINATION -"
                color: "#ff4444"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 16
                font.bold: true
                font.letterSpacing: 2
            }

            Text {
                text: "Select terminal action to terminate or sleep the local node:"
                color: "#90a8b8"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
            }

            Row {
                spacing: 14

                // SHUTDOWN
                Rectangle {
                    width: 130
                    height: 42
                    color: pwr1Mouse.containsMouse ? "#451216" : "#240a0c"
                    border.width: 1
                    border.color: pwr1Mouse.containsMouse ? "#ff3344" : "#631a20"

                    Text {
                        anchors.centerIn: parent
                        text: "SHUTDOWN"
                        color: "#ffffff"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        font.bold: true
                    }

                    MouseArea {
                        id: pwr1Mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: powerRoot.execPower("poweroff")
                    }
                }

                // REBOOT
                Rectangle {
                    width: 130
                    height: 42
                    color: pwr2Mouse.containsMouse ? "#302810" : "#1a1608"
                    border.width: 1
                    border.color: pwr2Mouse.containsMouse ? "#ffaa00" : "#594008"

                    Text {
                        anchors.centerIn: parent
                        text: "REBOOT"
                        color: "#ffffff"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        font.bold: true
                    }

                    MouseArea {
                        id: pwr2Mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: powerRoot.execPower("reboot")
                    }
                }

                // SUSPEND
                Rectangle {
                    width: 130
                    height: 42
                    color: pwr3Mouse.containsMouse ? "#0f2636" : "#081520"
                    border.width: 1
                    border.color: pwr3Mouse.containsMouse ? "#00b4e6" : "#163a4f"

                    Text {
                        anchors.centerIn: parent
                        text: "SUSPEND"
                        color: "#ffffff"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        font.bold: true
                    }

                    MouseArea {
                        id: pwr3Mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: powerRoot.execPower("suspend")
                    }
                }
            }

            // CANCEL
            Rectangle {
                width: 110
                height: 36
                anchors.right: parent.right
                color: cancelPwrMouse.containsMouse ? "#0a1a24" : "#071017"
                border.width: 1
                border.color: cancelPwrMouse.containsMouse ? "#80a0b0" : "#182c38"

                Text {
                    anchors.centerIn: parent
                    text: "ABORT"
                    color: cancelPwrMouse.containsMouse ? "#ffffff" : "#80a0b0"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                    font.bold: true
                }

                MouseArea {
                    id: cancelPwrMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: powerRoot.cancelClicked()
                }
            }
        }
    }
}
