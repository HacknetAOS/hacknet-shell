import QtQuick
import Quickshell
import Quickshell.Wayland
import "../singletons"

// One fixed-grid desktop per screen.
//
// Every region is positioned with explicit margins and ExclusionMode.Ignore so
// nothing is shifted twice by layer-shell exclusive zones. Geometry comes from
// Geo, which derives from the real screen size, so the grid scales.
Item {
    id: root
    required property var modelData
    property var screen: modelData
    Component.onCompleted: console.log("ScreenRoot created for", screen?.name || "unknown")

    readonly property int sw: root.screen ? root.screen.width : Geo.screenWidth
    readonly property int sh: root.screen ? root.screen.height : Geo.screenHeight

    // Prefer the grid compiled by hacknetd (design/layout.toml) so the frames
    // and the placed windows can never disagree. Fall back to local maths if
    // the daemon is not up yet.
    readonly property var grid: Daemon.rects
    readonly property real s: Math.max(0.75, Math.min(2.0, sh / 1080.0))
    readonly property int topH: grid ? grid.topbar.h : Math.round(26 * s)
    readonly property int gutterW: grid ? grid.sidebar.w : (Daemon.gutterHidden ? 0 : Math.round(sw * 0.133))
    readonly property int netH: grid ? grid.netmap.h : Math.round(184 * s)
    readonly property int termW: grid ? grid.terminal.w : Math.max(Math.round(360 * s), Math.round(sw * 0.381))
    readonly property int stageW: grid ? grid.stage.w : Math.max(Math.round(320 * s), sw - gutterW - termW)
    readonly property int stageH: grid ? grid.stage.h : Math.max(Math.round(240 * s), sh - topH - netH)

    // Background wash.
    PanelWindow {
        screen: root.screen
        anchors { top: true; left: true; right: true; bottom: true }
        exclusionMode: ExclusionMode.Ignore
        color: Theme.bg
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "hacknet-background"
        mask: Region {}

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#0a0912" }
                GradientStop { position: 0.55; color: Theme.bg }
                GradientStop { position: 1.0; color: "#0b0a14" }
            }
        }
    }

    // ------------------------------------------------------------- top strip
    PanelWindow {
        screen: root.screen
        anchors { top: true; left: true; right: true }
        implicitHeight: root.topH
        exclusionMode: ExclusionMode.Ignore
        color: Theme.bg
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "hacknet-topbar"
        TopBar { anchors.fill: parent }
    }

    // ---------------------------------------------------------- left gutter top
    // RAM readout panel — only the top block of the column. The middle of the
    // gutter stays free for dock terminal windows (hacknet-dock-N): each one is
    // a normal-layer window placed there by the daemon, with its own NetMap node.
    PanelWindow {
        screen: root.screen
        anchors { left: true; top: true }
        margins { top: root.topH }
        implicitWidth: root.gutterW
        implicitHeight: (Daemon.tokens ? Daemon.tokens.ram + Daemon.tokens.splitter
                                       : Math.round(96 * root.s))
        visible: !Daemon.gutterHidden
        exclusionMode: ExclusionMode.Ignore
        color: "#07070b"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "hacknet-gutter"
        mask: Region {}
        LeftDock { anchors.fill: parent; width: root.gutterW }
    }

    // -------------------------------------------------------- left gutter bottom
    // Vertical audio analyser, flush with the bottom-left. Media controls on hover.
    PanelWindow {
        screen: root.screen
        anchors { left: true; bottom: true }
        margins {
            left: Daemon.tokens ? Daemon.tokens.visualizer_padding : Math.round(12 * root.s)
            bottom: root.netH + (Daemon.tokens ? Daemon.tokens.visualizer_padding
                                               : Math.round(12 * root.s))
        }
        implicitWidth: Math.max(24, root.gutterW - 2 * (Daemon.tokens ? Daemon.tokens.visualizer_padding : Math.round(12 * root.s)))
        implicitHeight: Daemon.tokens ? Daemon.tokens.visualizer : Math.round(240 * root.s)
        visible: !Daemon.gutterHidden
        exclusionMode: ExclusionMode.Ignore
        color: "#07070b"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "hacknet-visualizer"
        Visualizer { anchors.fill: parent }
    }

    // ------------------------------------------------------- DISPLAY frame
    PanelWindow {
        screen: root.screen
        anchors { left: true; top: true }
        margins { left: root.grid ? root.grid.stage.x : root.gutterW; top: root.topH }
        implicitWidth: root.stageW
        implicitHeight: root.stageH
        exclusionMode: ExclusionMode.Ignore
        // Transparent: real application windows live on the normal layer below
        // this overlay, so an opaque panel would hide every stage app.
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "hacknet-display-frame"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        // Never take input: actual application windows live beneath this frame.
        mask: Region {}
        StageFrame { anchors.fill: parent }
    }

    // ------------------------------------------------- interactive home screen
    // Shown only while no stage window exists, so its action rows can receive
    // clicks; once a window opens this panel disappears and input goes to it.
    PanelWindow {
        screen: root.screen
        anchors { left: true; top: true }
        margins { left: root.grid ? root.grid.stage.x : root.gutterW; top: root.topH + 14 }
        width: root.stageW
        implicitWidth: root.stageW
        height: root.stageH - 14
        implicitHeight: root.stageH - 14
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        visible: !Ui.settingsOpen && !Ui.sessionOpen && !Ui.historyOpen && !Ui.locked && (Daemon.deckActive % 100 === 1 || !Daemon.stageWindows.some(w => w.deck === Daemon.deckActive))
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "hacknet-display-home"
        Component.onCompleted: console.log("display-home completed: w=", width, "h=", height, "stageW=", root.stageW, "visible=", visible)
        onVisibleChanged: console.log("display-home visibleChanged:", visible, "w=", width, "h:", height, "deckActive=", Daemon.deckActive, "stageWindows=", Daemon.stageWindows.length)

        Rectangle { anchors.fill: parent; color: Theme.bg }
        StageHome { anchors.fill: parent }
    }

    // ------------------------------------------------------ TERMINAL frame
    // Positioned from the daemon's grid so "console docked bottom-right only"
    // moves both the frame and the real foot window together.
    PanelWindow {
        screen: root.screen
        anchors { right: true; top: true }
        margins {
            top: root.grid ? root.grid.terminal.y : root.topH
            right: root.grid ? (root.sw - root.grid.terminal.x - root.grid.terminal.w) : 0
        }
        implicitWidth: root.grid ? root.grid.terminal.w : root.termW
        implicitHeight: root.grid ? root.grid.terminal.h : (root.sh - root.topH)
        exclusionMode: ExclusionMode.Ignore
        // Transparent: the docked foot window is a normal-layer client and must
        // show through this frame.
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "hacknet-terminal-frame"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        mask: Region {}
        RightTerminal { anchors.fill: parent }
    }

    // --------------------------------------------------------------- NETMAP
    PanelWindow {
        screen: root.screen
        anchors { left: true; bottom: true }
        margins { left: root.grid ? root.grid.netmap.x : 0 }
        implicitWidth: root.grid ? root.grid.netmap.w : (root.sw - root.termW)
        implicitHeight: root.netH
        exclusionMode: ExclusionMode.Ignore
        color: "#07070b"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "hacknet-netmap"
        NetMap { anchors.fill: parent }
    }

    // ------------------------------------------------------------- overlays
    PanelWindow {
        screen: root.screen
        anchors { top: true; left: true; right: true; bottom: true }
        exclusionMode: ExclusionMode.Ignore
        // Dim the desktop instead of replacing it with an opaque sheet, and sit
        // below the Overlay-layer dialogs so they are never hidden by the scrim.
        color: "#b307070b"
        visible: Ui.historyOpen || Ui.settingsOpen || Ui.sessionOpen || Ui.launcherOpen
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "hacknet-overlay"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        Item {
            anchors.fill: parent
            focus: Ui.historyOpen || Ui.settingsOpen || Ui.sessionOpen || Ui.launcherOpen
            Keys.onEscapePressed: Ui.closeAll()
            MouseArea { anchors.fill: parent; onClicked: Ui.closeAll() }
        }
    }

    // Application & command opener overlay (Super key)
    PanelWindow {
        screen: root.screen
        anchors { top: true; left: true }
        margins {
            top: Math.round(root.sh * 0.16)
            left: Math.round((root.sw - Math.min(root.sw - 40, 680)) / 2)
        }
        width: Math.min(root.sw - 40, 680)
        implicitWidth: Math.min(root.sw - 40, 680)
        height: Math.min(root.sh - 80, 520)
        implicitHeight: Math.min(root.sh - 80, 520)
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        visible: Ui.launcherOpen
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "hacknet-launcher"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        onVisibleChanged: if (visible) launcherModal.forceActiveFocus()
        AppLauncher {
            id: launcherModal
            anchors.fill: parent
            visible: Ui.launcherOpen
            focus: Ui.launcherOpen
            onVisibleChanged: if (visible) launcherModal.forceActiveFocus()
            Keys.onEscapePressed: Ui.closeAll()
        }
    }

    PanelWindow {
        screen: root.screen
        anchors { top: true; left: true }
        margins { top: Math.round((root.sh - Math.min(root.sh - 40, 730)) / 2)
                  left: Math.round((root.sw - Math.min(root.sw - 40, 540)) / 2) }
        width: Math.min(root.sw - 40, 540)
        implicitWidth: Math.min(root.sw - 40, 540)
        height: Math.min(root.sh - 40, 730)
        implicitHeight: Math.min(root.sh - 40, 730)
        exclusionMode: ExclusionMode.Ignore
        color: Theme.bg
        visible: Ui.settingsOpen
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "hacknet-settings"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        SettingsPanel {
            id: settingsModal
            anchors.fill: parent
            focus: Ui.settingsOpen
            onVisibleChanged: if (visible) settingsModal.forceActiveFocus()
            Keys.onEscapePressed: Ui.closeAll()
        }
    }

    PanelWindow {
        screen: root.screen
        anchors { top: true; left: true }
        margins { top: Math.round((root.sh - Math.min(root.sh - 50, 360)) / 2)
                  left: Math.round((root.sw - Math.min(root.sw - 40, 380)) / 2) }
        width: Math.min(root.sw - 40, 380)
        implicitWidth: Math.min(root.sw - 40, 380)
        height: Math.min(root.sh - 50, 360)
        implicitHeight: Math.min(root.sh - 50, 360)
        exclusionMode: ExclusionMode.Ignore
        color: Theme.bg
        visible: Ui.sessionOpen
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "hacknet-session"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        SessionMenu {
            id: sessionModal
            anchors.fill: parent
            focus: Ui.sessionOpen
            onVisibleChanged: if (visible) sessionModal.forceActiveFocus()
            Keys.onEscapePressed: Ui.closeAll()
        }
    }

    // Message history, opened by the envelope in the top strip.
    PanelWindow {
        screen: root.screen
        anchors { top: true; left: true }
        margins { top: Math.round((root.sh - Math.min(root.sh - 50, 500)) / 2)
                  left: Math.round((root.sw - Math.min(root.sw - 40, 560)) / 2) }
        width: Math.min(root.sw - 40, 560)
        implicitWidth: Math.min(root.sw - 40, 560)
        height: Math.min(root.sh - 50, 500)
        implicitHeight: Math.min(root.sh - 50, 500)
        exclusionMode: ExclusionMode.Ignore
        color: Theme.bg
        visible: Ui.historyOpen
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "hacknet-history"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        NotifHistory {
            id: historyModal
            anchors.fill: parent
            focus: Ui.historyOpen
            onVisibleChanged: if (visible) historyModal.forceActiveFocus()
            Keys.onEscapePressed: Ui.closeAll()
        }
    }

    // Notification popup, top-right, shown when a notification arrives.
    PanelWindow {
        screen: root.screen
        anchors { top: true; right: true }
        margins { top: root.topH + 8; right: 8 }
        width: Math.min(root.sw - 40, 360)
        implicitWidth: Math.min(root.sw - 40, 360)
        height: 112
        implicitHeight: 112
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        visible: Notifs.popupOpen
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "hacknet-notification"
        NotifPopup { anchors.fill: parent; notif: Notifs.popupData }
    }

    // Full-screen Hacknet session lock overlay.
    PanelWindow {
        screen: root.screen
        anchors { top: true; left: true; right: true; bottom: true }
        exclusionMode: ExclusionMode.Ignore
        color: "#07070b"
        visible: Ui.locked
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "hacknet-lock"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        LockScreen { anchors.fill: parent }
    }
}
