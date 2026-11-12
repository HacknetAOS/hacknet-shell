import QtQuick
import "../singletons"

// Vertical audio waveform.
//
// The game draws the spectrum as a thin glowing line down the gutter's right
// edge — no caption, no horizontal bar, no per-band blocks. Amplitude comes
// from the daemon's cava feed; without one it idles on a slow sine.
// On hover, shows media controls (play/pause, prev, next, volume).
Item {
    id: root

    readonly property var audio: Daemon.audio
    readonly property int points: 28
    property real phase: 0

    // Media controls visibility on hover
    property bool hovered: false
    property int hoverTimeout: 0

    Timer {
        interval: 90
        running: true
        repeat: true
        onTriggered: {
            root.phase += 0.14;
            canvas.requestPaint();
            if (hoverTimeout > 0) {
                hoverTimeout -= 90;
                if (hoverTimeout <= 0) {
                    hovered = false;
                }
            }
        }
    }

    function level(i) {
        if (root.audio && root.audio.length > 0) {
            const idx = Math.min(root.audio.length - 1,
                                 Math.floor(i * root.audio.length / root.points));
            return Math.max(0, Math.min(100, root.audio[idx])) / 100;
        }
        // Idle: two out-of-phase sines give a slow travelling wave.
        const a = Math.sin(i * 0.55 + root.phase);
        const b = Math.sin(i * 0.21 - root.phase * 0.6);
        return 0.5 + 0.34 * a * b;
    }

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            const ctx = getContext("2d");
            const w = width, h = height;
            ctx.clearRect(0, 0, w, h);
            if (w < 2 || h < 2) return;

            const n = root.points;
            const stepY = h / (n - 1);
            const cx = w / 2;

            // Soft glow pass, then the bright hairline, same as the game.
            for (let pass = 0; pass < 2; ++pass) {
                ctx.beginPath();
                for (let i = 0; i < n; ++i) {
                    const lvl = root.level(i);
                    const x = cx + (lvl - 0.5) * (w - 2);
                    const y = i * stepY;
                    if (i === 0) ctx.moveTo(x, y);
                    else ctx.lineTo(x, y);
                }
                ctx.lineWidth = pass === 0 ? 4.0 : 1.2;
                ctx.strokeStyle = pass === 0
                    ? Theme.alpha(Theme.accentGlow, 0.10)
                    : Theme.alpha(Theme.accentGlow, 0.85);
                ctx.stroke();
            }
        }
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Component.onCompleted: requestPaint()
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        onEntered: { root.hovered = true; }
        onExited: { root.hovered = false; }
    }

    // Media controls overlay on hover
    Rectangle {
        id: mediaControls
        anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
        height: root.hovered ? Math.max(30, Math.round(38 * Geo.scale)) : 0
        color: "#0b0d13"
        border.width: 1
        border.color: Theme.border
        opacity: root.hovered ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 150 } }
        Behavior on height { NumberAnimation { duration: 150 } }
        clip: true

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: { root.hovered = true; }
            onExited: { root.hovered = false; }
            propagateComposedEvents: true
            onPressed: (mouse) => { mouse.accepted = false; }
        }

        Row {
            anchors.centerIn: parent
            spacing: Math.max(6, Math.round(10 * Geo.scale))

            IconButton {
                kind: "prev"
                active: false
                onTriggered: Daemon.media("prev")
            }
            IconButton {
                kind: "play"
                active: false
                onTriggered: Daemon.media("play_pause")
            }
            IconButton {
                kind: "next"
                active: false
                onTriggered: Daemon.media("next")
            }
            IconButton {
                kind: "volume"
                active: false
                onTriggered: Daemon.run("hacknetctl", ["volume", "mute"])
            }
        }
    }

    Connections {
        target: Daemon
        function onAudioChanged() { canvas.requestPaint() }
    }
    Connections {
        target: Theme
        function onThemeChanged() { canvas.requestPaint() }
    }
}