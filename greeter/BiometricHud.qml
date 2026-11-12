import QtQuick

Item {
    id: bioRoot
    implicitWidth: 420
    implicitHeight: 64

    // States: "standby", "scanning", "success", "failed"
    property string bioState: "standby"
    property string statusMessage: "Place registered finger on reader or type password"
    property bool deviceDetected: true

    Rectangle {
        anchors.fill: parent
        color: bioRoot.bioState === "success" ? "#061f10"
             : (bioRoot.bioState === "failed" ? "#241505" : "#07131b")
        border.width: 1
        border.color: bioRoot.bioState === "success" ? "#5fdc53"
                    : (bioRoot.bioState === "failed" ? "#ffaa00" : "#1a3d4f")

        Row {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 14

            // Fingerprint scanner icon / status indicator
            Item {
                width: 44
                height: 44
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.width: 1
                    border.color: bioRoot.bioState === "success" ? "#5fdc53"
                                : (bioRoot.bioState === "failed" ? "#ffaa00" : "#00a2ff")
                    radius: 2

                    Text {
                        anchors.centerIn: parent
                        text: bioRoot.bioState === "success" ? "✓"
                            : (bioRoot.bioState === "failed" ? "!" : "󰈷") // Fingerprint nerd-font glyph or box
                        color: bioRoot.bioState === "success" ? "#5fdc53"
                             : (bioRoot.bioState === "failed" ? "#ffaa00" : "#00a2ff")
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 22
                        font.bold: true
                    }

                    // Scanning pulse beam
                    Rectangle {
                        id: scanBeam
                        width: parent.width
                        height: 2
                        color: bioRoot.bioState === "success" ? "#5fdc53"
                             : (bioRoot.bioState === "failed" ? "#ffaa00" : "#00f0ff")
                        opacity: 0.8
                        y: 0

                        SequentialAnimation on y {
                            running: bioRoot.bioState === "scanning" || bioRoot.bioState === "standby"
                            loops: Animation.Infinite
                            PropertyAnimation { to: 42; duration: 1600; easing.type: Easing.InOutQuad }
                            PropertyAnimation { to: 0; duration: 1600; easing.type: Easing.InOutQuad }
                        }
                    }
                }
            }

            // Text Info Column
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Text {
                    text: bioRoot.bioState === "success" ? "[ BIOMETRIC AUTH : VERIFIED ]"
                        : (bioRoot.bioState === "failed" ? "[ BIOMETRIC AUTH : RETRY ]"
                        : "[ BIOMETRIC SENSOR : ACTIVE ]")
                    color: bioRoot.bioState === "success" ? "#5fdc53"
                         : (bioRoot.bioState === "failed" ? "#ffaa00" : "#00b8e6")
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 1.2
                }

                Text {
                    text: bioRoot.statusMessage
                    color: "#7292a4"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                }
            }
        }
    }
}
