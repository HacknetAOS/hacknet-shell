pragma Singleton

import QtQuick

// Geometry for the fixed six-region grid.
//
// Proportions come from Hacknet's own layout at 1920x1080: the DISPLAY column
// ends around 61% of the width and the TERMINAL takes the rest; NETMAP is a
// short strip under DISPLAY; the top bar is a hairline.
Item {
    id: root

    property int screenWidth: 1920
    property int screenHeight: 1080

    // Hacknet's top strip is ~24px at 1080p.
    readonly property int topbarHeight: Math.round(22 * scale)

    // Left RAM gutter.
    readonly property int gutterWidth: Math.round(262 * scale)

    // NETMAP strip height.
    readonly property int netmapHeight: Math.round(184 * scale)

    // TERMINAL width: right ~39% of the screen.
    readonly property int terminalWidth: Math.max(360, Math.round(screenWidth * 0.39))

    readonly property int headerHeight: Math.round(14 * scale)

    readonly property real scale: Math.max(0.75, Math.min(2.0, screenHeight / 1080.0))

    readonly property int stageX: gutterWidth
    readonly property int stageY: topbarHeight
    readonly property int stageW: Math.max(320, screenWidth - gutterWidth - terminalWidth)
    readonly property int stageH: Math.max(240, screenHeight - topbarHeight - netmapHeight)

    readonly property int netmapX: 0
    readonly property int netmapY: screenHeight - netmapHeight
    readonly property int netmapW: screenWidth - terminalWidth

    readonly property int terminalX: screenWidth - terminalWidth
    readonly property int terminalY: topbarHeight
    readonly property int terminalH: screenHeight - topbarHeight

    // Vertical analyser sits in the left gutter, under the RAM readout.
    readonly property int visualizerWidth: Math.round(28 * scale)
    readonly property int visualizerHeight: Math.max(120, Math.round(screenHeight * 0.28))
    readonly property int visualizerX: Math.round(12 * scale)
    readonly property int visualizerY: Math.round(screenHeight - netmapHeight - visualizerHeight)
}
