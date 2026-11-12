pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// UI singleton: holds global UI state that multiple components need.
Singleton {
    id: root

    // Overlay visibility
    property bool historyOpen: false
    property bool settingsOpen: false
    property bool sessionOpen: false
    property bool launcherOpen: false
    property bool locked: false
    property bool gutterVisible: true  // RAM gutter visibility (Super+V)

    // Toggle functions
    function toggleHistory()  { historyOpen  = !historyOpen; }
    function toggleSettings() { settingsOpen = !settingsOpen; }
    function toggleSession()  { sessionOpen  = !sessionOpen; }
    function toggleLauncher() {
        if (launcherOpen) {
            launcherOpen = false;
        } else {
            closeAll();
            launcherOpen = true;
        }
    }
    function toggleGutter()   { gutterVisible = !gutterVisible; }

    function lockSession() {
        closeAll();
        locked = true;
    }

    function unlockSession() {
        locked = false;
    }

    // Close all overlays
    function closeAll() {
        historyOpen = false;
        settingsOpen = false;
        sessionOpen = false;
        launcherOpen = false;
    }

    // Unix domain socket server for instant sub-millisecond IPC triggers
    SocketServer {
        active: true
        path: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/hacknet-shell.sock"
        handler: Component {
            Socket {
                parser: SplitParser {
                    splitMarker: "\n"
                    onRead: (data) => {
                        let cmd = data.trim();
                        if (cmd === "launcher" || cmd === "toggle-launcher") {
                            root.toggleLauncher();
                        } else if (cmd === "open-launcher") {
                            root.closeAll();
                            root.launcherOpen = true;
                        } else if (cmd === "close-launcher") {
                            root.launcherOpen = false;
                        } else if (cmd === "lock") {
                            root.lockSession();
                        } else if (cmd === "unlock") {
                            root.unlockSession();
                        } else if (cmd === "settings") {
                            root.toggleSettings();
                        } else if (cmd === "session") {
                            root.toggleSession();
                        } else if (cmd === "history") {
                            root.toggleHistory();
                        } else if (cmd === "close") {
                            root.closeAll();
                        }
                    }
                }
            }
        }
    }

    Process {
        id: lockFilePoller
        command: ["sh", "-c", "test -f ~/.local/state/hacknet/locked && rm -f ~/.local/state/hacknet/locked"]
        onExited: (code, _status) => {
            if (code === 0 && !root.locked) {
                root.lockSession();
            }
        }
    }

    Process {
        id: launcherFilePoller
        command: ["sh", "-c", "test -f ~/.local/state/hacknet/launcher && rm -f ~/.local/state/hacknet/launcher"]
        onExited: (code, _status) => {
            if (code === 0) {
                root.toggleLauncher();
            }
        }
    }

    Timer {
        interval: 300
        running: true
        repeat: true
        onTriggered: {
            if (!lockFilePoller.running) lockFilePoller.running = true;
            if (!launcherFilePoller.running) launcherFilePoller.running = true;
        }
    }

    // Run a command via the daemon
    function run(cmd, args) {
        const argv = [cmd].concat(args || []);
        try {
            Quickshell.execDetached(argv);
        } catch (e) {
            console.warn("Ui.run failed:", argv.join(" "), e);
        }
    }
}