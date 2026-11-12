import QtQuick

Item {
    id: hexBgRoot
    anchors.fill: parent
    clip: true

    // Base background color (pitch black void)
    Rectangle {
        anchors.fill: parent
        color: "#000000"
    }

    // Dynamic sweeping wave illumination (angle -32 deg, 460px wavelength, 10.5s period matching in-game video)
    Item {
        anchors.centerIn: parent
        width: Math.max(parent.width, parent.height) * 3.0
        height: Math.max(parent.width, parent.height) * 3.0
        rotation: -32

        Row {
            id: waveRow
            x: 0
            y: (parent.height - 3600) / 2
            height: 3600

            Repeater {
                model: 16
                Rectangle {
                    width: 460
                    height: waveRow.height
                    color: "transparent"
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.00; color: "#00000000" }
                        GradientStop { position: 0.28; color: "#00000000" }
                        GradientStop { position: 0.39; color: "#0a0e14" }
                        GradientStop { position: 0.50; color: "#18202a" }
                        GradientStop { position: 0.61; color: "#0a0e14" }
                        GradientStop { position: 0.72; color: "#00000000" }
                        GradientStop { position: 1.00; color: "#00000000" }
                    }
                }
            }

            NumberAnimation on x {
                from: 0
                to: -460
                duration: 10500
                loops: Animation.Infinite
                running: true
            }
        }
    }

    // Hexagonal honeycomb grid mask (solid interlocking cells with dark seams and cell variation)
    Image {
        id: gridImage
        anchors.fill: parent
        source: "/usr/share/quickshell/hacknet/assets/hex_cells_mask.png"
        fillMode: Image.PreserveAspectCrop
        onStatusChanged: {
            if (status === Image.Error) {
                source = Qt.resolvedUrl("../assets/hex_cells_mask.png");
            }
        }
    }
}
