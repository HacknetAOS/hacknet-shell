import QtQuick

Item {
    id: preLoginRoot
    anchors.fill: parent

    property string lastUser: "alice"

    signal continueClicked()
    signal loginClicked()
    signal settingsClicked()
    signal exitClicked()

    // Official white geometric Hacknet OS logo
    Image {
        id: logo
        x: Math.round(parent.width * 0.094) // x ~ 180 on 1080p
        y: Math.round(parent.height * 0.124) // y ~ 134 on 1080p
        source: "/usr/share/quickshell/hacknet/assets/hacknet_logo.png"
        width: 459
        height: 61
        fillMode: Image.PreserveAspectFit
        onStatusChanged: {
            if (status === Image.Error) {
                // Fallback to relative path
                source = Qt.resolvedUrl("../assets/hacknet_logo.png");
            }
        }
    }

    // Action Menu Column (strictly matching game reference)
    Column {
        x: Math.round(parent.width * 0.094)
        y: Math.round(parent.height * 0.22)
        spacing: 14

        HacknetButton {
            text: "Continue with account [" + preLoginRoot.lastUser + "]"
            accentColor: "#8fa4b8"
            onClicked: preLoginRoot.continueClicked()
        }

        HacknetButton {
            text: "Login"
            accentColor: "#8fa4b8"
            onClicked: preLoginRoot.loginClicked()
        }

        HacknetButton {
            text: "Settings"
            accentColor: "#8fa4b8"
            onClicked: preLoginRoot.settingsClicked()
        }

        HacknetButton {
            text: "Exit"
            accentColor: "#a35858"
            onClicked: preLoginRoot.exitClicked()
        }
    }

    // Footer info
    Row {
        anchors.left: parent.left
        anchors.leftMargin: Math.round(parent.width * 0.094)
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 32
        spacing: 24

        Text {
            text: "STATUS : SYSTEM READY // HACKNET OS"
            color: "#687582"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 11
            font.letterSpacing: 1.5
        }

        Text {
            text: "TERMINAL LINK ESTABLISHED // SECURE NODE"
            color: "#4e5965"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 11
            font.letterSpacing: 1.5
        }
    }
}
