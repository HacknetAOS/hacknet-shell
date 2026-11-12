import QtQuick
import "../singletons"

Item {
    id: root
    property real strength: 0.15

    Canvas {
        anchors.fill: parent
        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            ctx.fillStyle = Theme.scanlineColor;
            for (let y = 0; y < height; y += 2) {
                ctx.fillRect(0, y, width, 1);
            }
        }
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }
}
