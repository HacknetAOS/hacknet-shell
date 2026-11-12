import QtQuick
import "../singletons"

// NETMAP strip.
//
// Reference (frames f5/f90/f180): purple caption bar, faint dot grid, a hub node
// for the operator's own machine (concentric rings plus a small satellite),
// filled discs with an inner ring for remote windows, joined by hairlines.
// Scaled circles to match the game's proportions.
Item {
    id: netmapRoot
    Component.onCompleted: console.log("NetMap component created", width, height)

    readonly property int nodeRadius: Math.max(14, Math.round(16 * Geo.scale))
    readonly property int captionH: Geo.headerHeight

    readonly property color ring: "#4a5578"
    readonly property color ringBright: "#7b86b8"
    readonly property color nodeFill: "#161b28"

    function hashStr(str) {
        let h = 0x811c9dc5;
        const s = String(str || "");
        for (let i = 0; i < s.length; i++) {
            h ^= s.charCodeAt(i);
            h = Math.imul(h, 0x01000193);
        }
        return h >>> 0;
    }

    // The operator's own machine always sits in the strip (the game calls it the
    // home machine); every other window gets its own grid cell, computed from
    // the strip size so circles and labels never overlap at any resolution.
    function visibleNodes() {
        // Filter by current desktop: each desktop has its own NetMap so apps
        // from desktop 1 are not shown on desktop 2.
        const curDesk = Daemon.currentDesktop || 1;
        const allNodes = (Daemon.nodes && Daemon.nodes.length > 0) ? Daemon.nodes : [];
        const list = allNodes.filter(function (n) {
            if (!n.deck || n.deck <= 0) return true; // sticky terminals / dock
            const desk = (n.deck < 100) ? 1 : Math.floor((n.deck - 1) / 100) + 1;
            return desk === curDesk;
        });

        // Sort by numeric id for stable ordering across clicks/repaints.
        list.sort(function (a, b) {
            const na = (String(a.id).startsWith("0x")) ? parseInt(a.id, 16) : parseInt(a.id, 10);
            const nb = (String(b.id).startsWith("0x")) ? parseInt(b.id, 16) : parseInt(b.id, 10);
            const ka = isNaN(na) ? Number.MAX_SAFE_INTEGER : na;
            const kb = isNaN(nb) ? Number.MAX_SAFE_INTEGER : nb;
            return ka - kb;
        });

        const padX = Math.round(26 * Geo.scale);
        const padY = Math.round(18 * Geo.scale);
        const r = nodeRadius;
        const homeR = Math.round(r * 1.5);
        const usableW = Math.max(120, frame.width - padX * 2);
        const usableH = Math.max(40, frame.height - padY * 2);

        // Home node occupies its own cell at the left edge, vertically centered.
        const home = {
            id: "home",
            label: Daemon.hostname,
            x: padX + homeR,
            y: Math.round(frame.height / 2),
            active: true,
            state: "normal",
            nodeClass: "local",
            deck: 1
        };
        if (list.length === 0) return [home];

        const startX = home.x + homeR + Math.round(20 * Geo.scale);
        const availableW = Math.max(120, frame.width - startX - padX);

        // Dynamic 2D grid scaling with NetMap dimensions:
        // Use 2 rows if height allows (>= 80px), else 1 row.
        const rows = (usableH >= Math.round(80 * Geo.scale)) ? 2 : 1;
        // Columns dynamically scale with node count so NO apps are dropped (> 6 apps supported!)
        const cols = Math.max(3, Math.ceil(list.length / rows));
        const cellW = availableW / cols;
        const cellH = usableH / rows;

        for (let i = 0; i < list.length; ++i) {
            const col = i % cols;
            // Stagger rows organically between columns
            const row = (rows > 1) ? ((col % 2 === 0) ? (Math.floor(i / cols) % rows) : (1 - (Math.floor(i / cols) % rows))) : 0;
            const cx = startX + col * cellW + cellW / 2;
            const cy = padY + row * cellH + cellH / 2;

            // Deterministic hash of node id for random organic scatter inside cell
            const h = hashStr(list[i].id);
            const maxJitterX = Math.max(0, (cellW / 2 - r - 6) * 0.6);
            const maxJitterY = Math.max(0, (cellH / 2 - r - 8) * 0.6);
            const jx = (((h % 1000) / 500) - 1.0) * maxJitterX;
            const jy = ((((h >> 10) % 1000) / 500) - 1.0) * maxJitterY;

            const finalX = Math.round(Math.min(frame.width - padX - r, Math.max(startX + r, cx + jx)));
            const finalY = Math.round(Math.min(frame.height - padY - r, Math.max(padY + r, cy + jy)));

            list[i] = Object.assign({}, list[i], {
                x: finalX,
                y: finalY
            });
        }
        // Return ALL nodes: every open app is visible and clickable!
        return [home].concat(list);
    }

    // How many characters fit inside one grid cell, so labels never collide.
    readonly property int labelChars: Math.max(6, Math.floor(
        (Math.max(Math.round(96 * Geo.scale), Math.round(nodeRadius * 1.5) * 2 + 26) - 8) / 6.2))

    // Edges come from the daemon (process-ancestry links), not hardcoded.
    function visibleEdges() {
        return (Daemon.edges && Daemon.edges.length > 0) ? Daemon.edges.slice() : [];
    }

    Rectangle {
        id: caption
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: netmapRoot.captionH
        color: Theme.captionBar
        border.width: 1
        border.color: Theme.captionLine

        Text {
            anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
            text: "NETMAP v1.7"
            color: Theme.captionFg
            font.family: Theme.mono
            font.pixelSize: Math.max(8, Theme.monoPx - 3)
            font.letterSpacing: 1
        }
    }

    Rectangle {
        id: frame
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom
                  top: caption.bottom }
        color: "transparent"
        border.width: 1
        border.color: Theme.border

        // Faint grid.
        Canvas {
            id: grid
            anchors.fill: parent
            opacity: 0.5
            onPaint: {
                const ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                ctx.fillStyle = Theme.alpha(Theme.grid, 0.85);
                for (let x = 22; x < width; x += 44)
                    for (let y = 18; y < height; y += 28)
                        ctx.fillRect(x, y, 1, 1);
            }
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            Component.onCompleted: requestPaint()
        }

        // Links between nodes - drawn from daemon edge data.
        Canvas {
            id: lines
            anchors.fill: parent
            onPaint: {
                const ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                ctx.strokeStyle = Theme.alpha(Theme.fg, 0.45);
                ctx.lineWidth = Math.max(1, 1.2 * Geo.scale);
                const list = netmapRoot.visibleNodes();
                const derived = netmapRoot.visibleEdges();
                // Build id -> node lookup.
                const byId = {};
                for (let j = 0; j < list.length; ++j) byId[list[j].id] = list[j];
                for (let i = 0; i < derived.length; ++i) {
                    const e = derived[i];
                    const a = byId[e.from];
                    const b = byId[e.to];
                    if (!a || !b) continue;
                    const ra = (a.nodeClass === "local") ? netmapRoot.nodeRadius * 1.5 : netmapRoot.nodeRadius;
                    const rb = (b.nodeClass === "local") ? netmapRoot.nodeRadius * 1.5 : netmapRoot.nodeRadius;
                    const dx = b.x - a.x;
                    const dy = b.y - a.y;
                    const dist = Math.sqrt(dx * dx + dy * dy);
                    if (dist > ra + rb) {
                        const ux = dx / dist;
                        const uy = dy / dist;
                        ctx.beginPath();
                        ctx.moveTo(a.x + ux * ra, a.y + uy * ra);
                        ctx.lineTo(b.x - ux * rb, b.y - uy * rb);
                        ctx.stroke();
                    }
                }
                if (derived.length === 0 && list.length === 1) {
                    // Nothing connected yet: a short fading stub.
                    const n = list[0], r = netmapRoot.nodeRadius * 1.5;
                    ctx.beginPath();
                    ctx.moveTo(n.x + r + 4, n.y);
                    ctx.lineTo(n.x + r + Math.round(70 * Geo.scale), n.y);
                    ctx.stroke();
                }
            }
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            Connections {
                target: Daemon
                function onNodesChanged() { lines.requestPaint() }
                function onEdgesChanged() { lines.requestPaint() }
                function onCurrentDesktopChanged() { lines.requestPaint() }
            }
            Connections {
                target: Theme
                function onThemeChanged() {
                    lines.requestPaint();
                    nodesCanvas.requestPaint();
                    grid.requestPaint();
                }
            }
        }

        // Animated nodes layer
        Item {
            id: nodesContainer
            anchors.fill: parent
            z: 15

            property var nodeList: netmapRoot.visibleNodes()

            function refresh() {
                nodeList = netmapRoot.visibleNodes();
            }

            Repeater {
                model: nodesContainer.nodeList
                Item {
                    id: nodeDelegate
                    required property var modelData
                    property bool isHome: (modelData.nodeClass || "") === "local"
                    property bool isActive: !!modelData.active
                    property int nodeD: isHome ? Math.round(48 * Geo.scale) : Math.round(36 * Geo.scale)

                    x: Math.round(modelData.x - nodeD / 2)
                    y: Math.round(modelData.y - nodeD / 2)
                    width: nodeD
                    height: nodeD

                    AnimatedImage {
                        anchors.fill: parent
                        source: isHome ? Qt.resolvedUrl("../assets/nodes/hacknet_netmap_node_player.gif")
                                       : (isActive ? Qt.resolvedUrl("../assets/nodes/hacknet_netmap_node_connected_transparent.gif")
                                                   : Qt.resolvedUrl("../assets/nodes/hacknet_netmap_node_transparent.gif"))
                        playing: true
                        smooth: true
                        mipmap: true
                        asynchronous: false
                    }

                    Text {
                        anchors.top: parent.bottom
                        anchors.topMargin: Math.round(2 * Geo.scale)
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: {
                            let lbl = String(modelData.label || "");
                            const maxLen = netmapRoot.labelChars;
                            if (lbl.length > maxLen) lbl = lbl.slice(0, maxLen - 1) + "\u2026";
                            return lbl;
                        }
                        color: isActive ? "#ffffff" : "#9a94c8"
                        font.bold: isActive
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: Math.max(9, Math.round(10 * Geo.scale))
                    }
                }
            }

            Connections {
                target: Daemon
                function onNodesChanged() { nodesContainer.refresh() }
                function onEdgesChanged() { nodesContainer.refresh() }
                function onCurrentDesktopChanged() { nodesContainer.refresh() }
            }
            Connections {
                target: frame
                function onWidthChanged() { nodesContainer.refresh() }
                function onHeightChanged() { nodesContainer.refresh() }
            }
        }

        // Click/tap handling for nodes - hit detection on the canvas.
        MouseArea {
            id: nodeArea
            anchors.fill: parent
            z: 20
            hoverEnabled: true
            cursorShape: Qt.ArrowCursor
            property real hoverX: 0
            property real hoverY: 0
            onPositionChanged: { hoverX = mouse.x; hoverY = mouse.y; cursorShape = hoverNodeId() !== "" ? Qt.PointingHandCursor : Qt.ArrowCursor }
            acceptedButtons: Qt.LeftButton | Qt.RightButton

            function nodeAt(px, py) {
                const list = nodesContainer.nodeList;
                const pad = 8; // forgiving hit area: labels and antialiasing eat pixels
                for (let i = 0; i < list.length; ++i) {
                    const n = list[i];
                    const isHome = (n.nodeClass || "") === "local";
                    const R = (isHome ? Math.round(24 * Geo.scale) : Math.round(18 * Geo.scale)) + pad;
                    const dx = px - n.x, dy = py - n.y;
                    if (dx * dx + dy * dy <= R * R) return n;
                }
                return null;
            }

            function hoverNodeId() {
                const n = nodeAt(hoverX, hoverY);
                return n ? n.id : "";
            }

            onClicked: (mouse) => {
                const n = nodeAt(mouse.x, mouse.y);
                if (!n) { nodeMenu.visible = false; return; }
                if (mouse.button === Qt.RightButton) {
                    nodeMenu.open(n.id, mouse.x, mouse.y);
                } else {
                    nodeMenu.visible = false;
                    Daemon.activateNode(n.id);
                }
            }

            onPressAndHold: (mouse) => {
                const n = nodeAt(mouse.x, mouse.y);
                if (n) nodeMenu.open(n.id, mouse.x, mouse.y);
            }
        }

        // Right-click / long-press menu for a netmap node.
        Rectangle {
            id: nodeMenu
            visible: false
            z: 30
            width: 132
            height: nodeMenu.nodeId === "home" ? 26 : 52
            color: "#0b0d13"
            border.width: 1
            border.color: Theme.border
            property string nodeId: ""

            function open(id, px, py) {
                nodeId = id;
                x = Math.max(0, Math.min(px, parent.width - width));
                y = Math.max(0, Math.min(py, parent.height - height));
                visible = true;
            }

            Column {
                anchors.fill: parent
                anchors.margins: 1
                spacing: 1

                Rectangle {
                    id: focusItem
                    width: parent.width; height: 24
                    color: "#0b0d13"
                    Text {
                        anchors.centerIn: parent
                        text: "FOCUS"
                        color: Theme.captionFg
                        font.family: Theme.mono
                        font.pixelSize: Math.max(9, Theme.monoPx - 1)
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: focusItem.color = Theme.btnHover
                        onExited: focusItem.color = "#0b0d13"
                        onClicked: { Daemon.activateNode(nodeMenu.nodeId); nodeMenu.visible = false; }
                    }
                }
                Rectangle {
                    id: closeItem
                    visible: nodeMenu.nodeId !== "home"
                    width: parent.width; height: 24
                    color: "#0b0d13"
                    Text {
                        anchors.centerIn: parent
                        text: "CLOSE"
                        color: Theme.captionFg
                        font.family: Theme.mono
                        font.pixelSize: Math.max(9, Theme.monoPx - 1)
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: closeItem.color = Theme.btnHover
                        onExited: closeItem.color = "#0b0d13"
                        onClicked: { Daemon.kill(nodeMenu.nodeId); nodeMenu.visible = false; }
                    }
                }
            }
        }
    }}
