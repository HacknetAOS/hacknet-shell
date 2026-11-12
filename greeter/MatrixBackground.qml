import QtQuick

// Ambient memory matrix background effect matching Hacknet source material.
Item {
    id: bgRoot
    anchors.fill: parent

    Rectangle {
        anchors.fill: parent
        color: "#050a0f"
    }

    Canvas {
        id: matrixCanvas
        anchors.fill: parent
        renderTarget: Canvas.FramebufferObject

        property var particles: []
        readonly property int particleCount: 75

        function randHex(len) {
            const chars = "0123456789ABCDEF";
            let s = "";
            for (let i = 0; i < len; i++) s += chars.charAt(Math.floor(Math.random() * chars.length));
            return s;
        }

        function createParticle() {
            const types = ["addr", "hex", "node", "dot", "ip"];
            const t = types[Math.floor(Math.random() * types.length)];
            let text = "";
            if (t === "addr") text = "0x" + randHex(4) + ":" + randHex(4);
            else if (t === "hex") text = randHex(2) + " " + randHex(2) + " " + randHex(2) + " " + randHex(2);
            else if (t === "node") text = "[ " + randHex(3) + " ]";
            else if (t === "ip") text = "192.168." + Math.floor(Math.random() * 254 + 1) + "." + Math.floor(Math.random() * 254 + 1);
            else text = ". . : . .";

            return {
                text: text,
                x: Math.random() * width,
                y: Math.random() * height,
                speedY: 0.15 + Math.random() * 0.45,
                alpha: 0.08 + Math.random() * 0.22,
                baseAlpha: 0.08 + Math.random() * 0.22,
                size: Math.floor(9 + Math.random() * 4),
                isCyan: Math.random() > 0.4,
                flickerTimer: Math.random() * 100
            };
        }

        Component.onCompleted: {
            const pts = [];
            for (let i = 0; i < particleCount; i++) {
                pts.push(createParticle());
            }
            particles = pts;
            animTimer.start();
        }

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            // Subtle dark radial gradient in center
            const cx = width / 2;
            const cy = height / 2;
            const grad = ctx.createRadialGradient(cx, cy, 50, cx, cy, Math.max(width, height) * 0.8);
            grad.addColorStop(0.0, "rgba(7, 24, 38, 0.4)");
            grad.addColorStop(1.0, "rgba(4, 8, 12, 0.95)");
            ctx.fillStyle = grad;
            ctx.fillRect(0, 0, width, height);

            // Draw particles
            for (let i = 0; i < particles.length; i++) {
                const p = particles[i];
                ctx.font = p.size + 'px "JetBrainsMono Nerd Font", monospace';
                const colorStr = p.isCyan
                    ? ("rgba(0, 180, 230, " + p.alpha.toFixed(3) + ")")
                    : ("rgba(130, 160, 180, " + p.alpha.toFixed(3) + ")");
                ctx.fillStyle = colorStr;
                ctx.fillText(p.text, p.x, p.y);
            }
        }

        Timer {
            id: animTimer
            interval: 40 // ~25-30 fps for smooth, ultra-low-CPU ambient animation
            repeat: true
            running: false
            onTriggered: {
                const pts = matrixCanvas.particles;
                const h = matrixCanvas.height;
                const w = matrixCanvas.width;
                if (h <= 0 || w <= 0) return;

                for (let i = 0; i < pts.length; i++) {
                    const p = pts[i];
                    p.y -= p.speedY;
                    if (p.y < -20) {
                        p.y = h + 10;
                        p.x = Math.random() * w;
                    }
                    p.flickerTimer += 1;
                    if (p.flickerTimer > 30) {
                        p.alpha = Math.max(0.04, Math.min(0.35, p.baseAlpha + (Math.random() - 0.5) * 0.1));
                        p.flickerTimer = 0;
                    }
                }
                matrixCanvas.requestPaint();
            }
        }
    }

    // Scanline & Cathode overlay
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.color: "#0a2030"
        border.width: 1

        Canvas {
            anchors.fill: parent
            opacity: 0.12
            onPaint: {
                const ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                ctx.fillStyle = "rgba(0, 0, 0, 0.7)";
                for (let y = 0; y < height; y += 3) {
                    ctx.fillRect(0, y, width, 1);
                }
            }
        }
    }
}
