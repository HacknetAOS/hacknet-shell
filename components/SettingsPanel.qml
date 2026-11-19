import QtQuick
import Quickshell
import "../singletons"

// Control Center: quick hardware & media controls only.
// Full OS, desktop, theme, and keybind settings live in hacknet-settings.
Rectangle {
    id: root
    implicitWidth: 520
    implicitHeight: 560

    color: "#0b0d13"
    border.width: 1
    border.color: Theme.border

    Text {
        id: caption
        anchors { left: parent.left; top: parent.top; leftMargin: 10; topMargin: 6 }
        text: "CONTROL CENTER"
        color: Theme.dim
        font.family: Theme.mono
        font.pixelSize: Math.max(8, Theme.monoPx - 2)
        font.letterSpacing: 1
    }

    Rectangle {
        anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 24 }
        height: 1
        color: Theme.borderDim
    }

    Flickable {
        id: flick
        anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 30
                  bottom: parent.bottom }
        contentHeight: contentColumn.height + 24
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Rectangle {
            id: scrollTrack
            anchors { right: parent.right; top: parent.top; bottom: parent.bottom; rightMargin: 2 }
            width: 8
            color: Theme.borderDim
            visible: flick.visibleArea.heightRatio < 1.0

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                y: flick.visibleArea.yPosition * flick.height
                height: Math.max(20, flick.visibleArea.heightRatio * flick.height)
                color: Theme.highlight
            }

            MouseArea {
                anchors.fill: parent
                preventStealing: true
                onPositionChanged: (mouse) => {
                    const ratio = Math.max(0, Math.min(1.0, mouse.y / scrollTrack.height));
                    flick.contentY = ratio * (flick.contentHeight - flick.height);
                }
                onPressed: (mouse) => {
                    const ratio = Math.max(0, Math.min(1.0, mouse.y / scrollTrack.height));
                    flick.contentY = ratio * (flick.contentHeight - flick.height);
                }
            }
        }

        WheelHandler {
            target: flick
            onWheel: (event) => {
                flick.contentY = Math.max(0, Math.min(flick.contentHeight - flick.height, flick.contentY - event.angleDelta.y));
            }
        }

        Column {
            id: contentColumn
            anchors { left: parent.left; right: parent.right; leftMargin: 18; rightMargin: 18 }
            spacing: 14

            // -------------------------------------------------------- VOLUME
            Text {
                text: "VOLUME"
                color: "#9aa0ab"
                font.family: Theme.mono
                font.pixelSize: Theme.monoPx
                font.letterSpacing: 1
            }

            HacknetSlider {
                width: parent.width
                label: "OUTPUT VOLUME"
                value: Math.min(1.0, Daemon.currentVolume)
                displayValue: Daemon.isMuted ? "MUTED" : Math.round(Daemon.currentVolume * 100) + "%"
                onValueChangedByUser: (val) => Daemon.setVolume(val)
            }

            LauncherButton {
                label: Daemon.isMuted ? "UNMUTE" : "MUTE"
                active: Daemon.isMuted
                onTriggered: Daemon.toggleMute()
            }

            Rectangle { width: parent.width; height: 1; color: Theme.borderDim }

            // ------------------------------------------------ MEDIA CONTROLS
            Text {
                text: "MEDIA CONTROLS"
                color: "#9aa0ab"
                font.family: Theme.mono
                font.pixelSize: Theme.monoPx
                font.letterSpacing: 1
            }

            Flow {
                width: parent.width
                spacing: 8

                LauncherButton {
                    label: "PREV"
                    onTriggered: Daemon.run("hacknetctl", ["media", "prev"])
                }

                LauncherButton {
                    label: "PLAY / PAUSE"
                    onTriggered: Daemon.run("hacknetctl", ["media", "play_pause"])
                }

                LauncherButton {
                    label: "STOP"
                    onTriggered: Daemon.run("hacknetctl", ["media", "stop"])
                }

                LauncherButton {
                    label: "NEXT"
                    onTriggered: Daemon.run("hacknetctl", ["media", "next"])
                }
            }

            // -------------------------------------------- DISPLAY BRIGHTNESS
            Rectangle {
                width: parent.width; height: 1; color: Theme.borderDim
                visible: Daemon.hasBrightness
            }

            Text {
                text: "DISPLAY BRIGHTNESS"
                color: "#9aa0ab"
                font.family: Theme.mono
                font.pixelSize: Theme.monoPx
                font.letterSpacing: 1
                visible: Daemon.hasBrightness
            }

            HacknetSlider {
                width: parent.width
                visible: Daemon.hasBrightness
                label: "BRIGHTNESS"
                value: Daemon.currentBrightness
                onValueChangedByUser: (val) => Daemon.setBrightness(val)
            }

            // ------------------------------------------------- WIFI SETTINGS
            Rectangle {
                width: parent.width; height: 1; color: Theme.borderDim
                visible: Daemon.hasWifi
            }

            Text {
                text: "WIFI SETTINGS"
                color: "#9aa0ab"
                font.family: Theme.mono
                font.pixelSize: Theme.monoPx
                font.letterSpacing: 1
                visible: Daemon.hasWifi
            }

            Column {
                id: wifiSection
                width: parent.width
                spacing: 8
                visible: Daemon.hasWifi
                property string connectingSsid: ""

                Row {
                    spacing: 8
                    LauncherButton {
                        label: "WIFI: " + (Daemon.wifiEnabled ? "ON" : "OFF")
                        active: Daemon.wifiEnabled
                        onTriggered: Daemon.toggleWifi()
                    }
                    LauncherButton {
                        label: Daemon.wifiScanning ? "SCANNING..." : "SCAN NETWORKS"
                        onTriggered: Daemon.scanWifi()
                    }
                }

                Text {
                    text: Daemon.wifiActiveSsid ? ("CONNECTED: " + Daemon.wifiActiveSsid) : "DISCONNECTED"
                    color: Daemon.wifiActiveSsid ? Theme.accent : Theme.dim
                    font.family: Theme.mono
                    font.pixelSize: Math.max(9, Theme.monoPx - 1)
                }

                Column {
                    width: parent.width
                    spacing: 6
                    visible: Daemon.wifiEnabled && Daemon.wifiNetworks.length > 0

                    Repeater {
                        model: Daemon.wifiNetworks
                        delegate: Rectangle {
                            width: parent.width
                            height: (wifiSection.connectingSsid === modelData.ssid) ? 68 : 32
                            color: modelData.inUse ? "#141724" : "#0d0f17"
                            border.width: 1
                            border.color: modelData.inUse ? Theme.accent : Theme.borderDim

                            Column {
                                anchors.fill: parent
                                anchors.margins: 4
                                spacing: 4

                                Item {
                                    width: parent.width
                                    height: 24

                                    Row {
                                        anchors.left: parent.left
                                        anchors.right: wifiBtn.left
                                        anchors.rightMargin: 8
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 8

                                        Text {
                                            width: 160
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: (modelData.inUse ? "* " : "  ") + modelData.ssid
                                            color: modelData.inUse ? "#ffffff" : Theme.fg
                                            font.family: Theme.mono
                                            font.pixelSize: Math.max(9, Theme.monoPx - 1)
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "[" + modelData.signal + "%]"
                                            color: Theme.accent
                                            font.family: Theme.mono
                                            font.pixelSize: Math.max(8, Theme.monoPx - 2)
                                        }

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "[" + modelData.security + "]"
                                            color: Theme.dim
                                            font.family: Theme.mono
                                            font.pixelSize: Math.max(8, Theme.monoPx - 2)
                                        }
                                    }

                                    LauncherButton {
                                        id: wifiBtn
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        label: modelData.inUse ? "DISCONNECT" : "CONNECT"
                                        active: modelData.inUse
                                        onTriggered: {
                                            if (modelData.inUse) {
                                                Daemon.disconnectWifi(modelData.ssid);
                                            } else if (modelData.security === "OPEN" || modelData.security === "--") {
                                                Daemon.connectWifi(modelData.ssid, "");
                                            } else {
                                                wifiSection.connectingSsid = modelData.ssid;
                                            }
                                        }
                                    }
                                }

                                Row {
                                    width: parent.width
                                    height: 28
                                    spacing: 8
                                    visible: wifiSection.connectingSsid === modelData.ssid

                                    Rectangle {
                                        width: 200
                                        height: 26
                                        color: "#07080d"
                                        border.width: 1
                                        border.color: Theme.accent

                                        TextInput {
                                            id: wifiPassInput
                                            anchors.fill: parent
                                            anchors.margins: 4
                                            echoMode: TextInput.Password
                                            color: "#ffffff"
                                            font.family: Theme.mono
                                            font.pixelSize: Theme.monoPx - 1
                                            focus: parent.parent.visible
                                        }
                                        Text {
                                            anchors.fill: parent
                                            anchors.margins: 4
                                            text: "Enter password..."
                                            color: Theme.dim
                                            font.family: Theme.mono
                                            font.pixelSize: Theme.monoPx - 1
                                            visible: wifiPassInput.text.length === 0
                                        }
                                    }

                                    LauncherButton {
                                        label: "JOIN"
                                        onTriggered: {
                                            Daemon.connectWifi(modelData.ssid, wifiPassInput.text);
                                            wifiSection.connectingSsid = "";
                                        }
                                    }

                                    LauncherButton {
                                        label: "CANCEL"
                                        onTriggered: wifiSection.connectingSsid = ""
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // -------------------------------------------- BLUETOOTH SETTINGS
            Rectangle {
                width: parent.width; height: 1; color: Theme.borderDim
                visible: Daemon.hasBluetooth
            }

            Text {
                text: "BLUETOOTH SETTINGS"
                color: "#9aa0ab"
                font.family: Theme.mono
                font.pixelSize: Theme.monoPx
                font.letterSpacing: 1
                visible: Daemon.hasBluetooth
            }

            Column {
                width: parent.width
                spacing: 8
                visible: Daemon.hasBluetooth

                Row {
                    spacing: 8
                    LauncherButton {
                        label: "BLUETOOTH: " + (Daemon.btEnabled ? "ON" : "OFF")
                        active: Daemon.btEnabled
                        onTriggered: Daemon.toggleBluetooth()
                    }
                    LauncherButton {
                        label: Daemon.btScanning ? "SCANNING..." : "SCAN DEVICES"
                        onTriggered: Daemon.scanBluetooth()
                    }
                }

                Column {
                    width: parent.width
                    spacing: 6
                    visible: Daemon.btEnabled && Daemon.btDevices.length > 0

                    Repeater {
                        model: Daemon.btDevices
                        delegate: Rectangle {
                            width: parent.width
                            height: 32
                            color: "#0d0f17"
                            border.width: 1
                            border.color: Theme.borderDim

                            Item {
                                anchors.fill: parent
                                anchors.margins: 4

                                Row {
                                    anchors.left: parent.left
                                    anchors.right: btConnBtn.left
                                    anchors.rightMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 8

                                    Text {
                                        width: 180
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.name || modelData.mac
                                        color: Theme.fg
                                        font.family: Theme.mono
                                        font.pixelSize: Math.max(9, Theme.monoPx - 1)
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.mac
                                        color: Theme.dim
                                        font.family: Theme.mono
                                        font.pixelSize: Math.max(8, Theme.monoPx - 2)
                                    }
                                }

                                LauncherButton {
                                    id: btConnBtn
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    label: "CONNECT"
                                    onTriggered: Daemon.connectBluetooth(modelData.mac)
                                }
                            }
                        }
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.borderDim }

            Row {
                spacing: 8

                LauncherButton {
                    label: "OPEN SETTINGS"
                    onTriggered: {
                        Ui.closeAll();
                        Quickshell.execDetached(["hacknet-settings"]);
                    }
                }

                LauncherButton {
                    label: "CLOSE"
                    onTriggered: Ui.closeAll()
                }
            }
        }
    }
}
