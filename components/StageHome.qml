import QtQuick
import "../singletons"

// Default DISPLAY content.
//
// Game reference (frame f180): a line-art machine, "Connected to", the machine
// name, its address, then a column of flat action rows. Here the rows open real
// local tools in the stage, so the screen is useful as well as faithful.
Item {
    id: root

    readonly property var rows: [
        { label: "Terminal", cmd: "hacknet-term", args: ["--app-id", "hacknet-stage"] },
        { label: "View Filesystem", cmd: "thunar", args: [] },
    ]

    // Line-art monitor: screen with content lines, neck and base.
    Canvas {
        id: glyph
        x: Math.round(34 * Geo.scale)
        y: Math.round(26 * Geo.scale)
        width: Math.round(96 * Geo.scale)
        height: Math.round(82 * Geo.scale)
        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            const s = width / 96;
            ctx.strokeStyle = Theme.alpha(Theme.fg, 0.85);
            ctx.lineWidth = Math.max(1, 1.6 * s);
            ctx.strokeRect(10 * s, 2 * s, 76 * s, 52 * s);
            ctx.strokeStyle = Theme.alpha(Theme.fg, 0.30);
            ctx.beginPath();
            ctx.moveTo(18 * s, 14 * s); ctx.lineTo(52 * s, 14 * s);
            ctx.moveTo(18 * s, 22 * s); ctx.lineTo(70 * s, 22 * s);
            ctx.moveTo(18 * s, 30 * s); ctx.lineTo(46 * s, 30 * s);
            ctx.stroke();
            ctx.strokeStyle = Theme.alpha(Theme.fg, 0.85);
            ctx.beginPath();
            ctx.moveTo(40 * s, 54 * s); ctx.lineTo(40 * s, 66 * s);
            ctx.lineTo(56 * s, 66 * s); ctx.lineTo(56 * s, 54 * s);
            ctx.moveTo(28 * s, 72 * s); ctx.lineTo(68 * s, 72 * s);
            ctx.stroke();
        }
    }

    Connections {
        target: Theme
        function onThemeChanged() { glyph.requestPaint() }
    }

    Column {
        id: headline
        anchors { left: glyph.right; leftMargin: Math.round(24 * Geo.scale); top: glyph.top; topMargin: 2 }
        spacing: Math.round(4 * Geo.scale)

        Text {
            text: "Connected to"
            color: "#c9ccd3"
            font.family: Theme.mono
            font.pixelSize: Math.round(24 * Geo.scale)
        }
        Text {
            text: Daemon.username + "@" + Daemon.hostname
            color: "#b9a6ff"
            font.family: Theme.mono
            font.pixelSize: Math.round(16 * Geo.scale)
        }
    }

    Column {
        id: actions
        anchors { left: headline.left; top: headline.bottom; topMargin: Math.round(24 * Geo.scale) }
        width: Math.round(340 * Geo.scale)
        spacing: Math.round(16 * Geo.scale)

        Repeater {
            model: root.rows
            delegate: LauncherButton {
                width: actions.width
                label: modelData.label
                onTriggered: Ui.run(modelData.cmd || "hacknet-term", modelData.args)
            }
        }
    }
}