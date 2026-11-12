import QtQuick
import "../singletons"

// Settings / control center, styled like a Hacknet window: grey caption strip,
// flat buttons, no rounded panels or coloured gradients.
// Sections appear dynamically based on available hardware/commands.
Rectangle {
    id: root
    implicitWidth: 520
    implicitHeight: 640

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

    // Scrollable content: the control center holds more sections than fit on
    // small outputs, so nothing is ever cut off.
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

            // -------------------------------------------------------- THEME
            Text {
                text: "THEME"
                color: "#9aa0ab"
                font.family: Theme.mono
                font.pixelSize: Theme.monoPx
                font.letterSpacing: 1
            }

            Flow {
                width: parent.width
                spacing: 8
                Repeater {
                    model: [
                        { id: "blue",   name: "BLUE"   },
                        { id: "ente",   name: "ENTE"   },
                        { id: "hellhound", name: "HELLHOUND" },
                        { id: "naix",   name: "NAIX"   },
                        { id: "hacknet", name: "HACKNET" }
                    ]
                    delegate: LauncherButton {
                        label: modelData.name
                        active: Theme.themeId === modelData.id
                        onTriggered: Daemon.setTheme(modelData.id)
                    }
                }
            }

            // Admin-configurable default theme from /etc/hacknetos/theme.cfg
            Text {
                width: parent.width
                text: "config: " + (Daemon.themeCfg || "blue")
                color: Theme.dim
                font.family: Theme.mono
                font.pixelSize: Math.max(7, Theme.monoPx - 3)
                visible: Daemon.themeCfg !== ""
            }

            Rectangle { width: parent.width; height: 1; color: Theme.borderDim }

            // ------------------------------------------------------ DISPLAY
            Text {
                text: "DISPLAY"
                color: "#9aa0ab"
                font.family: Theme.mono
                font.pixelSize: Theme.monoPx
                font.letterSpacing: 1
            }

            HacknetSlider {
                width: parent.width
                visible: Daemon.hasBrightness
                label: "BRIGHTNESS"
                value: Daemon.currentBrightness
                onValueChangedByUser: (val) => Daemon.setBrightness(val)
            }

            Flow {
                width: parent.width
                spacing: 8

                LauncherButton {
                    label: "RAM GUTTER: " + (Daemon.gutterHidden ? "OFF" : "ON")
                    active: !Daemon.gutterHidden
                    onTriggered: Daemon.run("hacknetctl", ["toggle-gutter"])
                }

                LauncherButton {
                    label: "CONSOLE: " + (Daemon.terminalBottomOnly
                                          ? "BOTTOM RIGHT" : "FULL COLUMN")
                    active: !Daemon.terminalBottomOnly
                    onTriggered: Daemon.toggleTerminalBottomOnly()
                }

                LauncherButton {
                    label: "FULLSCREEN"
                    visible: Daemon.stageWindows.length > 0
                    onTriggered: {
                        const w = Daemon.stageWindows.find(x => x.active)
                                  || Daemon.stageWindows[0];
                        if (w) Daemon.setFullscreen(String(w.id), true);
                    }
                }

                LauncherButton {
                    label: "LEAVE FULLSCREEN"
                    visible: Daemon.fullscreenActive
                    onTriggered: {
                        if (Daemon.fullscreenWindow)
                            Daemon.setFullscreen(Daemon.fullscreenWindow, false);
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.borderDim }

            // -------------------------------------------------------- AUDIO
            Text {
                text: "AUDIO"
                color: "#9aa0ab"
                font.family: Theme.mono
                font.pixelSize: Theme.monoPx
                font.letterSpacing: 1
            }

            HacknetSlider {
                width: parent.width
                label: "VOLUME"
                value: Math.min(1.0, Daemon.currentVolume)
                displayValue: Daemon.isMuted ? "MUTED" : Math.round(Daemon.currentVolume * 100) + "%"
                onValueChangedByUser: (val) => Daemon.setVolume(val)
            }

            Flow {
                width: parent.width
                spacing: 8

                LauncherButton {
                    label: Daemon.isMuted ? "UNMUTE" : "MUTE"
                    active: Daemon.isMuted
                    onTriggered: Daemon.toggleMute()
                }

                LauncherButton {
                    label: "PLAY / PAUSE"
                    onTriggered: Daemon.run("hacknetctl", ["media", "play_pause"])
                }

                LauncherButton {
                    label: "PREV"
                    onTriggered: Daemon.run("hacknetctl", ["media", "prev"])
                }

                LauncherButton {
                    label: "NEXT"
                    onTriggered: Daemon.run("hacknetctl", ["media", "next"])
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.borderDim }

            // ------------------------------------------------ NOTIFICATIONS
            Text {
                text: "NOTIFICATIONS"
                color: "#9aa0ab"
                font.family: Theme.mono
                font.pixelSize: Theme.monoPx
                font.letterSpacing: 1
            }

            Flow {
                width: parent.width
                spacing: 8

                LauncherButton {
                    label: "DO NOT DISTURB: " + (Daemon.dnd ? "ON" : "OFF")
                    active: Daemon.dnd
                    onTriggered: Daemon.setDnd(!Daemon.dnd)
                }

                LauncherButton {
                    label: "CLEAR HISTORY"
                    onTriggered: Notifs.clear()
                }
            }

            Rectangle {
                width: parent.width; height: 1; color: Theme.borderDim
                visible: Daemon.hasWifi || Daemon.hasBluetooth
            }

            // ------------------------------------------------------ NETWORK
            // Only shown when the hardware exists.
            Text {
                text: "NETWORK"
                color: "#9aa0ab"
                font.family: Theme.mono
                font.pixelSize: Theme.monoPx
                font.letterSpacing: 1
                visible: Daemon.hasWifi || Daemon.hasBluetooth
            }

            // Wi-Fi Section
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

            // Bluetooth Section
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

            // ----------------------------------------------------- DESKTOPS
            Text {
                text: "DESKTOPS"
                color: "#9aa0ab"
                font.family: Theme.mono
                font.pixelSize: Theme.monoPx
                font.letterSpacing: 1
            }

            Row {
                spacing: 8

                LauncherButton {
                    label: "+ NEW DESKTOP"
                    onTriggered: Daemon.addDesktop()
                }

                LauncherButton {
                    label: "- REMOVE"
                    visible: Daemon.desktopCount > 1
                    onTriggered: Daemon.removeDesktop(Daemon.currentDesktop)
                }
            }

            Flow {
                width: parent.width
                spacing: 8

                Repeater {
                    model: Daemon.desktopCount
                    delegate: LauncherButton {
                        label: "D" + (index + 1)
                        active: Daemon.currentDesktop === (index + 1)
                        onTriggered: Daemon.switchDesktop(index + 1)
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.borderDim }

            // ------------------------------------------------------- SYSTEM
            Text {
                text: "SYSTEM"
                color: "#9aa0ab"
                font.family: Theme.mono
                font.pixelSize: Theme.monoPx
                font.letterSpacing: 1
            }

            Text {
                width: parent.width
                text: "host " + Daemon.hostname + "   addr " + Daemon.homeAddress
                      + "\nuser " + Daemon.username + "   kernel " + Daemon.version
                color: Theme.dim
                font.family: Theme.mono
                font.pixelSize: Math.max(9, Theme.monoPx - 1)
                lineHeight: 1.3
            }

            Item { width: 1; height: 6 }

            LauncherButton {
                label: "CLOSE"
                onTriggered: Ui.closeAll()
            }
        }
    }
}
