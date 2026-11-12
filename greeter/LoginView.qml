import QtQuick

Item {
    id: loginRoot
    anchors.fill: parent

    property alias username: usernameField.text
    property alias password: passwordField.text
    property var accountList: ["alice", "operator"]
    property string errorMessage: ""
    property bool fingerprintConfigured: false
    property string bioMessage: ""

    signal cancelClicked()
    signal loginRequested(string user, string pass)
    signal userSelected(string user)

    function resetFields() {
        passwordField.text = "";
        errorMessage = "";
        passwordField.forceActiveFocus();
    }

    onVisibleChanged: {
        if (visible) {
            resetFields();
        }
    }

    // Top-right LOCAL ACCOUNTS panel (matches loginScreen.jpg)
    Item {
        id: accountsPanel
        x: Math.round(parent.width * 0.59) // x ~ 1140 on 1080p
        y: Math.round(parent.height * 0.25) // y ~ 275 on 1080p
        width: 324

        Column {
            width: parent.width
            spacing: 8

            Text {
                text: "LOCAL ACCOUNTS ::"
                color: "#8fa4b8"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
                font.bold: true
                font.letterSpacing: 1.5
            }

            Column {
                width: parent.width
                spacing: 6

                Repeater {
                    model: loginRoot.accountList
                    delegate: Rectangle {
                        required property string modelData
                        width: accountsPanel.width
                        height: 26
                        color: mouseArea.containsMouse ? "#222730" : (loginRoot.username === modelData ? "#1e242c" : "#14171d")
                        border.width: 1
                        border.color: loginRoot.username === modelData ? "#8fa4b8" : (mouseArea.containsMouse ? "#606872" : "#383e46")

                        // Left accent tab
                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: 10
                            color: loginRoot.username === modelData ? "#8fa4b8" : (mouseArea.containsMouse ? "#55606e" : "transparent")
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 18
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData
                            color: loginRoot.username === modelData ? "#ffffff" : "#b0bcc8"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                            font.bold: loginRoot.username === modelData
                        }

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                loginRoot.username = modelData;
                                loginRoot.userSelected(modelData);
                                loginRoot.resetFields();
                            }
                        }
                    }
                }
            }
        }
    }

    // Centered-left Login Form (matches loginScreen.jpg)
    Item {
        id: formContainer
        x: Math.round(parent.width * 0.25) // x ~ 480 on 1080p
        y: Math.round(parent.height * 0.44) // y ~ 480 on 1080p
        width: 360

        Column {
            width: parent.width
            spacing: 12

            // System Branding: HACKNET OS
            Text {
                text: "HACKNET OS"
                color: "#8fa4b8"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
                font.bold: true
                font.letterSpacing: 2.5
            }

            // Title: - Login -
            Text {
                text: "- Login -"
                color: "#d8e2ea"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 22
                font.bold: true
                font.letterSpacing: 2
            }

            // USERNAME LINE
            Row {
                width: parent.width
                spacing: 8

                Text {
                    text: "USERNAME :"
                    color: "#8fa4b8"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }

                TextInput {
                    id: usernameField
                    width: parent.width - 120
                    height: 22
                    text: "alice"
                    color: "#ffffff"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    selectByMouse: true
                    cursorVisible: activeFocus
                    KeyNavigation.tab: passwordField
                    onAccepted: passwordField.forceActiveFocus()
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // PASSWORD LINE
            Row {
                width: parent.width
                spacing: 8

                Text {
                    text: "PASSWORD :"
                    color: "#8fa4b8"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }

                TextInput {
                    id: passwordField
                    width: parent.width - 120
                    height: 22
                    color: "#ffffff"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    echoMode: TextInput.Password
                    selectByMouse: true
                    cursorVisible: activeFocus
                    focus: true
                    KeyNavigation.tab: usernameField
                    onAccepted: loginRoot.loginRequested(usernameField.text, passwordField.text)
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // Thin Horizontal Divider Line (x=480..809 in loginScreen.jpg)
            Rectangle {
                width: parent.width
                height: 1
                color: "#6e7782"
            }

            // Action Buttons Row (CANCEL / CONNECT)
            Row {
                spacing: 14

                // CANCEL button (red accent tab)
                Rectangle {
                    width: 110
                    height: 26
                    color: cancelMouse.containsMouse ? "#242830" : "#181b20"
                    border.width: 1
                    border.color: cancelMouse.containsMouse ? "#8fa4b8" : "#4e5661"

                    // Left red accent tab
                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 12
                        color: "#a35858"
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "CANCEL"
                        color: cancelMouse.containsMouse ? "#ffffff" : "#c0ccd8"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        font.bold: true
                        font.letterSpacing: 1.0
                    }

                    MouseArea {
                        id: cancelMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: loginRoot.cancelClicked()
                    }
                }

                // CONNECT button (blue accent tab)
                Rectangle {
                    width: 120
                    height: 26
                    color: connectMouse.containsMouse ? "#242830" : "#181b20"
                    border.width: 1
                    border.color: connectMouse.containsMouse ? "#8fa4b8" : "#4e5661"

                    // Left blue accent tab
                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 12
                        color: "#5084a4"
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "CONNECT"
                        color: connectMouse.containsMouse ? "#ffffff" : "#c0ccd8"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        font.bold: true
                        font.letterSpacing: 1.0
                    }

                    MouseArea {
                        id: connectMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: loginRoot.loginRequested(usernameField.text, passwordField.text)
                    }
                }
            }

            // Fingerprint reader text (ONLY visible if fingerprint setup was completed)
            Text {
                visible: loginRoot.fingerprintConfigured
                text: loginRoot.bioMessage !== "" ? loginRoot.bioMessage : "[ FINGERPRINT SENSOR READY - SCAN OR ENTER PASSWORD ]"
                color: "#8fa4b8"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
                font.letterSpacing: 1.0
            }

            // Authentication Error Text
            Text {
                visible: loginRoot.errorMessage !== ""
                text: "ERROR // " + loginRoot.errorMessage
                color: "#e05555"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
                font.bold: true
                font.letterSpacing: 0.8
            }
        }
    }
}
