import QtQuick
import "../singletons"

// Top-strip icon, drawn rather than taken from a font so the shapes match the
// game's simple monochrome marks (no emoji-style glyphs).
Item {
    id: root

    // "close" | "gear" | "server" | "folder" | "monitor" | "power" | "mail"
    property string kind: "close"
    property bool active: false
    signal triggered()

    // The game draws these in near-white, not dim grey.
    readonly property color tint: mouse.containsMouse || root.active ? "#ffffff" : "#e6e4f2"

    implicitWidth: Math.round(17 * Geo.scale)
    implicitHeight: implicitWidth
    width: implicitWidth
    height: implicitHeight

    onTintChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        onPaint: {
            const ctx = getContext("2d");
            const w = width, h = height;
            ctx.clearRect(0, 0, w, h);
            ctx.strokeStyle = root.tint;
            ctx.fillStyle = root.tint;
            ctx.lineWidth = Math.max(1.4, w * 0.11);

            if (root.kind === "close") {
                ctx.beginPath();
                ctx.moveTo(w * 0.18, h * 0.18); ctx.lineTo(w * 0.82, h * 0.82);
                ctx.moveTo(w * 0.82, h * 0.18); ctx.lineTo(w * 0.18, h * 0.82);
                ctx.stroke();
            } else if (root.kind === "gear") {
                // Proper cogwheel with teeth
                const cx = w / 2, cy = h / 2;
                const outerR = w * 0.42;
                const innerR = w * 0.22;
                const teeth = 8;
                ctx.beginPath();
                for (let i = 0; i < teeth * 2; ++i) {
                    const angle = (i * Math.PI) / teeth;
                    const r = (i % 2 === 0) ? outerR : innerR;
                    const x = cx + r * Math.cos(angle);
                    const y = cy + r * Math.sin(angle);
                    if (i === 0) ctx.moveTo(x, y);
                    else ctx.lineTo(x, y);
                }
                ctx.closePath();
                ctx.stroke();
                // Center hole
                ctx.beginPath();
                ctx.arc(w / 2, h / 2, innerR * 0.5, 0, Math.PI * 2);
                ctx.stroke();
            } else if (root.kind === "server") {
                // Hacknet's "machine" mark: a rack with a notch and bay lines.
                ctx.strokeRect(w * 0.18, h * 0.12, w * 0.64, h * 0.76);
                ctx.beginPath();
                ctx.moveTo(w * 0.40, h * 0.12); ctx.lineTo(w * 0.40, h * 0.24);
                ctx.lineTo(w * 0.60, h * 0.24); ctx.lineTo(w * 0.60, h * 0.12);
                ctx.stroke();
                for (let i = 0; i < 3; ++i) {
                    const y = h * (0.38 + i * 0.16);
                    ctx.beginPath();
                    ctx.moveTo(w * 0.26, y); ctx.lineTo(w * 0.74, y);
                    ctx.stroke();
                }
            } else if (root.kind === "mail") {
                ctx.strokeRect(w * 0.10, h * 0.24, w * 0.80, h * 0.54);
                ctx.beginPath();
                ctx.moveTo(w * 0.10, h * 0.24);
                ctx.lineTo(w * 0.50, h * 0.56);
                ctx.lineTo(w * 0.90, h * 0.24);
                ctx.stroke();
            } else if (root.kind === "folder") {
                ctx.beginPath();
                ctx.moveTo(w * 0.1, h * 0.28);
                ctx.lineTo(w * 0.42, h * 0.28);
                ctx.lineTo(w * 0.5, h * 0.38);
                ctx.lineTo(w * 0.9, h * 0.38);
                ctx.lineTo(w * 0.9, h * 0.78);
                ctx.lineTo(w * 0.1, h * 0.78);
                ctx.closePath();
                ctx.stroke();
            } else if (root.kind === "monitor") {
                ctx.strokeRect(w * 0.1, h * 0.14, w * 0.8, h * 0.56);
                ctx.beginPath();
                ctx.moveTo(w * 0.40, h * 0.70); ctx.lineTo(w * 0.40, h * 0.82);
                ctx.lineTo(w * 0.60, h * 0.82); ctx.lineTo(w * 0.60, h * 0.70);
                ctx.moveTo(w * 0.26, h * 0.88); ctx.lineTo(w * 0.74, h * 0.88);
                ctx.stroke();
            } else if (root.kind === "power") {
                ctx.beginPath();
                ctx.arc(w / 2, h * 0.56, w * 0.30, Math.PI * 0.75, Math.PI * 2.25);
                ctx.stroke();
                ctx.beginPath();
                ctx.moveTo(w / 2, h * 0.16); ctx.lineTo(w / 2, h * 0.50);
                ctx.stroke();
            } else if (root.kind === "play") {
                ctx.beginPath();
                ctx.moveTo(w * 0.30, h * 0.22);
                ctx.lineTo(w * 0.78, h * 0.50);
                ctx.lineTo(w * 0.30, h * 0.78);
                ctx.closePath();
                ctx.fill();
            } else if (root.kind === "pause") {
                ctx.fillRect(w * 0.26, h * 0.22, w * 0.16, h * 0.56);
                ctx.fillRect(w * 0.58, h * 0.22, w * 0.16, h * 0.56);
            } else if (root.kind === "prev") {
                ctx.fillRect(w * 0.20, h * 0.22, w * 0.10, h * 0.56);
                ctx.beginPath();
                ctx.moveTo(w * 0.76, h * 0.22);
                ctx.lineTo(w * 0.34, h * 0.50);
                ctx.lineTo(w * 0.76, h * 0.78);
                ctx.closePath();
                ctx.fill();
            } else if (root.kind === "next") {
                ctx.beginPath();
                ctx.moveTo(w * 0.24, h * 0.22);
                ctx.lineTo(w * 0.66, h * 0.50);
                ctx.lineTo(w * 0.24, h * 0.78);
                ctx.closePath();
                ctx.fill();
                ctx.fillRect(w * 0.70, h * 0.22, w * 0.10, h * 0.56);
            } else if (root.kind === "volume") {
                ctx.beginPath();
                ctx.moveTo(w * 0.16, h * 0.38);
                ctx.lineTo(w * 0.34, h * 0.38);
                ctx.lineTo(w * 0.54, h * 0.20);
                ctx.lineTo(w * 0.54, h * 0.80);
                ctx.lineTo(w * 0.34, h * 0.62);
                ctx.lineTo(w * 0.16, h * 0.62);
                ctx.closePath();
                ctx.fill();
                ctx.beginPath();
                ctx.arc(w * 0.44, h * 0.50, w * 0.26, -Math.PI * 0.28, Math.PI * 0.28);
                ctx.stroke();
                ctx.beginPath();
                ctx.arc(w * 0.44, h * 0.50, w * 0.40, -Math.PI * 0.28, Math.PI * 0.28);
                ctx.stroke();
            } else if (root.kind === "search") {
                const cx = w * 0.40, cy = h * 0.40, r = w * 0.26;
                ctx.beginPath();
                ctx.arc(cx, cy, r, 0, Math.PI * 2);
                ctx.stroke();
                ctx.beginPath();
                ctx.moveTo(cx + r * 0.707, cy + r * 0.707);
                ctx.lineTo(w * 0.85, h * 0.85);
                ctx.stroke();
            }
        }
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Component.onCompleted: requestPaint()
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.triggered()
    }
}