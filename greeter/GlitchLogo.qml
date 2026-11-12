import QtQuick

Item {
    id: logoRoot
    implicitWidth: 500
    implicitHeight: 110

    property bool glitching: false
    property real glitchOffsetX: 0
    property real glitchOffsetY: 0

    // Red chromatic aberration layer
    Text {
        visible: logoRoot.glitching
        x: logoRoot.glitchOffsetX
        y: logoRoot.glitchOffsetY
        text: "HACKNET OS"
        color: "#ff1744"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 64
        font.bold: true
        font.letterSpacing: 8
        opacity: 0.8
    }

    // Cyan chromatic aberration layer
    Text {
        visible: logoRoot.glitching
        x: -logoRoot.glitchOffsetX * 0.8
        y: -logoRoot.glitchOffsetY * 0.6
        text: "HACKNET OS"
        color: "#00e5ff"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 64
        font.bold: true
        font.letterSpacing: 8
        opacity: 0.85
    }

    // Main base text
    Text {
        id: mainText
        anchors.left: parent.left
        anchors.top: parent.top
        text: "HACKNET OS"
        color: "#ededed"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 64
        font.bold: true
        font.letterSpacing: 8
    }

    // Subtitle tagline
    Text {
        anchors.left: mainText.left
        anchors.top: mainText.bottom
        anchors.topMargin: -4
        text: "OPERATING SYSTEM v0.1 // TERMINAL LINK ESTABLISHED"
        color: "#3d738a"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 11
        font.letterSpacing: 2
    }

    // Glitch trigger timer
    Timer {
        id: glitchTimer
        interval: 3200
        repeat: true
        running: true
        onTriggered: {
            logoRoot.glitchOffsetX = (Math.random() - 0.5) * 8;
            logoRoot.glitchOffsetY = (Math.random() - 0.5) * 4;
            logoRoot.glitching = true;
            glitchResetTimer.start();
        }
    }

    Timer {
        id: glitchResetTimer
        interval: 110
        running: false
        onTriggered: {
            logoRoot.glitching = false;
            // Randomize next interval
            glitchTimer.interval = Math.floor(2500 + Math.random() * 3000);
        }
    }
}
