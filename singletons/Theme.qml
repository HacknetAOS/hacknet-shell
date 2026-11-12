pragma Singleton

import QtQuick
import Quickshell

// Theme singleton: every colour the shell draws comes from here.
// The palette follows the theme applied by hacknet-theme (blue/ente/hellhound/
// naix/white), so switching themes restyles the whole desktop, not just foot.
Singleton {
    id: root

    property string themeId: "blue"
    property real scale: 1.0

    readonly property var palettes: ({
        "blue": {
            bg: "#07070b", fg: "#b9a6ff", dim: "#797fa6",
            topbarBg: "#07070b", topbarLine: "#1a1a2e",
            captionBar: "#241b4e", captionLine: "#8687bd", captionFg: "#c9ccd3",
            labelBg: "#805e9e", labelFg: "#101010",
            border: "#2b3b52", borderDim: "#1a1a2e", grid: "#1a1a2e",
            accent: "#6f86bb", accentGlow: "#805e9e", accentDim: "#4a5578",
            alert: "#a8322a", alertStrip: "#5f1211",
            btnBg: "#1d1454", btnHover: "#2a2a5a", btnActive: "#6f86bb",
            btnText: "#e6e4f2", btnBorder: "#8687bd", accentStrip: "#1a1a2e"
        },
        "ente": {
            bg: "#060d09", fg: "#8ef0b0", dim: "#5f8a6d",
            topbarBg: "#060d09", topbarLine: "#13291b",
            captionBar: "#123822", captionLine: "#4f9c6c", captionFg: "#cfe8d8",
            labelBg: "#2f7a4f", labelFg: "#08120c",
            border: "#1d4a30", borderDim: "#13291b", grid: "#13291b",
            accent: "#3f9e68", accentGlow: "#2f7a4f", accentDim: "#2a6b46",
            alert: "#a8322a", alertStrip: "#5f1211",
            btnBg: "#0f2a1a", btnHover: "#17402a", btnActive: "#3f9e68",
            btnText: "#dff5e6", btnBorder: "#4f9c6c", accentStrip: "#1a2e1a"
        },
        "hellhound": {
            bg: "#0d0707", fg: "#ffb59a", dim: "#a07468",
            topbarBg: "#0d0707", topbarLine: "#2a1310",
            captionBar: "#3a1712", captionLine: "#b5563f", captionFg: "#f0d5cc",
            labelBg: "#8a3a2a", labelFg: "#140806",
            border: "#4a201a", borderDim: "#2a1310", grid: "#2a1310",
            accent: "#b8442a", accentGlow: "#8a3a2a", accentDim: "#6b2e22",
            alert: "#d0453a", alertStrip: "#5f1211",
            btnBg: "#2a100c", btnHover: "#3d1812", btnActive: "#b8442a",
            btnText: "#f5e0d8", btnBorder: "#b5563f", accentStrip: "#2e1a1a"
        },
        "naix": {
            bg: "#060b0f", fg: "#8fdcff", dim: "#65849a",
            topbarBg: "#060b0f", topbarLine: "#122330",
            captionBar: "#123247", captionLine: "#4c8fb5", captionFg: "#d2e8f2",
            labelBg: "#2f6f8a", labelFg: "#04121a",
            border: "#1d4256", borderDim: "#122330", grid: "#122330",
            accent: "#3a8fc4", accentGlow: "#2f6f8a", accentDim: "#2a6079",
            alert: "#a8322a", alertStrip: "#5f1211",
            btnBg: "#0d2230", btnHover: "#143242", btnActive: "#3a8fc4",
            btnText: "#e2f2fa", btnBorder: "#4c8fb5", accentStrip: "#122330"
        },
        "hacknet": {
            bg: "#0a0a0a", fg: "#00ff00", dim: "#008800",
            topbarBg: "#0a0a0a", topbarLine: "#004400",
            captionBar: "#002200", captionLine: "#00ff00", captionFg: "#00ff00",
            labelBg: "#00ff00", labelFg: "#0a0a0a",
            border: "#00ff00", borderDim: "#004400", grid: "#004400",
            accent: "#00ff00", accentGlow: "#00aa00", accentDim: "#004400",
            alert: "#ff0000", alertStrip: "#440000",
            btnBg: "#002200", btnHover: "#004400", btnActive: "#00ff00",
            btnText: "#00ff00", btnBorder: "#00ff00", accentStrip: "#002200"
        }
    })

    readonly property var p: palettes[themeId] || palettes["blue"]

    readonly property color bg: p.bg
    readonly property color fg: p.fg
    readonly property color dim: p.dim
    readonly property color topbarBg: p.topbarBg
    readonly property color topbarLine: p.topbarLine
    readonly property color captionBar: p.captionBar
    readonly property color captionLine: p.captionLine
    readonly property color captionFg: p.captionFg
    readonly property color labelBg: p.labelBg
    readonly property color labelFg: p.labelFg
    readonly property color border: p.border
    readonly property color borderDim: p.borderDim
    readonly property color grid: p.grid
    readonly property color accent: p.accent
    readonly property color accentGlow: p.accentGlow
    readonly property color accentDim: p.accentDim
    readonly property color alert: p.alert
    readonly property color alertStrip: p.alertStrip
    readonly property color btnBg: p.btnBg
    readonly property color btnHover: p.btnHover
    readonly property color btnActive: p.btnActive
    readonly property color btnText: p.btnText
    readonly property color btnBorder: p.btnBorder

    // Legacy names used by the original components.
    readonly property color buttonBg: p.btnBg
    readonly property color buttonHover: p.btnHover
    readonly property color buttonBorder: p.btnBorder
    readonly property color accentStrip: p.accentStrip
    readonly property color scanlineColor: p.accentDim

    // Legacy names still referenced by a few components.
    readonly property color netmapRing: p.border
    readonly property color netmapRingBright: p.captionLine
    readonly property color netmapNodeFill: p.bg
    readonly property color frameBg: p.bg

    readonly property string mono: "JetBrainsMono Nerd Font, JetBrains Mono, monospace"
    readonly property string ui: "JetBrainsMono Nerd Font, JetBrains Mono, monospace"
    readonly property int mono_size: 11
    readonly property int monoPx: Math.max(9, Math.round(mono_size * (scale || 1)))

    readonly property real scanlines: 0.0

    function applyTheme(id) {
        if (palettes[id] && id !== themeId) {
            themeId = id;
            console.log("theme now", id);
            themeChanged();
        }
    }

    signal themeChanged

    function alpha(color, a) {
        const s = String(color);
        if (s.charAt(0) === "#" && s.length === 7) {
            return Qt.rgba(parseInt(s.slice(1, 3), 16) / 255,
                           parseInt(s.slice(3, 5), 16) / 255,
                           parseInt(s.slice(5, 7), 16) / 255, a);
        }
        return color;
    }
}
