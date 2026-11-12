pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Window state
    property var windows: []
    property var stageWindows: []
    property var sidebarWindows: []
    property var terminalWindows: []
    property int stageCount: 0
    property int deckActive: 1

    // System info
    // Hacknet shows a short hex identifier for the local machine and the node
    // you are currently attached to.
    property string hostname: "hacknetos"
    property string homeAddress: "9cc71bc0"
    property string locationName: "Operator Terminal"
    property string username: Quickshell.env("USER") || "operator"
    property string version: "1.0.0"
    property string backend: "hyprland"
    property bool connected: true
    // Rects compiled by hacknetd from design/layout.toml: the single source of
    // truth for the grid, shared with the shell panels.
    property var rects: null
    property var tokens: null
    property var memory: ({ total: 0, used: 0, pct: 0, swap_total: 0, swap_used: 0 })
    property var logs: []
    property var nodes: []
    property var edges: []
    property var audio: []

    // Audio visualization
    property var audioData: []

    // UI state
    property bool dnd: false
    property int unread: 0
    property bool settingsOpen: false
    property bool historyOpen: false
    property bool sessionOpen: false
    property bool gutterVisible: true  // RAM gutter visibility
    property bool gutterHidden: false  // daemon-owned: sidebar collapsed
    property bool terminalBottomOnly: false  // console docked bottom-right only
    property var lastError: ""
    
    // Virtual desktops / workspaces
    property int currentDesktop: 1
    property int desktopCount: 1
    property var desktops: []
    
    // Fullscreen state
    property var fullscreenWindow: null
    property bool fullscreenActive: false
    // Hardware capability detection for dynamic control center sections.
    property bool hasBrightness: false
    property bool hasWifi: false
    property bool hasBluetooth: false
    property string themeCfg: ""  // theme id from /etc/hacknetos/theme.cfg

    // ------------------------------------------------------------- daemon link
    // hacknetd owns window/netmap state. Polling `hacknetctl state` keeps the
    // shell in sync without hand-rolling a socket reader in QML.
    function applyState(text) {
        if (!text || text.length === 0) return;
        let j;
        try { j = JSON.parse(text); } catch (e) { return; }

        if (j.backend) root.backend = j.backend;
        if (j.version) root.version = j.version;
        if (typeof j.deck_active === "number") root.deckActive = j.deck_active;
        if (typeof j.dnd === "boolean") root.dnd = j.dnd;
        if (j.theme_id) Theme.applyTheme(j.theme_id);
        if (typeof j.gutter_hidden === "boolean") root.gutterHidden = j.gutter_hidden;
        if (typeof j.terminal_bottom_only === "boolean")
            root.terminalBottomOnly = j.terminal_bottom_only;
        if (typeof j.desktop_count === "number") root.desktopCount = j.desktop_count;
        if (typeof j.current_desktop === "number") root.currentDesktop = j.current_desktop;

        if (Array.isArray(j.windows)) {
            root.windows = j.windows;
            root.stageWindows = j.windows.filter(w => String(w.zone || "").toLowerCase() === "stage");
            root.sidebarWindows = j.windows.filter(w => String(w.zone || "").toLowerCase() === "sidebar");
            root.terminalWindows = j.windows.filter(w => String(w.zone || "").toLowerCase() === "terminal");
            root.stageCount = root.stageWindows.length;
            root.connected = true;
        }

        if (j.rects) root.rects = j.rects;
        if (j.tokens) root.tokens = j.tokens;

        if (j.netmap && Array.isArray(j.netmap.nodes)) {
            // Reassign to trigger QML binding update
            root.nodes = j.netmap.nodes;
            root.edges = j.netmap.edges || [];
            root.nodesChanged();
        }

        if (j.memory && j.memory.total_kb) {
            const m = j.memory;
            root.memory = ({
                total: m.total_kb,
                used: m.used_kb,
                pct: m.pct,
                swap_total: (m.swap_total_kb || 0) / 1048576,
                swap_used: (m.swap_used_kb || 0) / 1048576
            });
        }

        if (j.audio && Array.isArray(j.audio)) {
            root.audio = j.audio;
            root.audioChanged();
        }
    }

    Process {
        id: stateProc
        command: ["hacknetctl", "state"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.applyState(text)
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!stateProc.running) stateProc.running = true;
        }
    }

    Component.onCompleted: console.log("Daemon singleton created")

    // ---------------------------------------------------------------- telemetry
    // Values the sidebar renders. memory.total/used are KiB (memoryText divides
    // by 1024*1024); swap_* are GiB (the sidebar prints them directly).
    function updateMemory(text) {
        if (!text) return;
        let totalKb = 0, availKb = 0, swapTotalKb = 0, swapFreeKb = 0;
        const lines = text.split("\n");
        for (let i = 0; i < lines.length; ++i) {
            const m = lines[i].match(/^(\w+):\s+(\d+)/);
            if (!m) continue;
            const kb = parseInt(m[2], 10);
            switch (m[1]) {
                case "MemTotal":     totalKb = kb; break;
                case "MemAvailable": availKb = kb; break;
                case "SwapTotal":    swapTotalKb = kb; break;
                case "SwapFree":     swapFreeKb = kb; break;
            }
        }
        if (totalKb <= 0) return;
        const usedKb = Math.max(0, totalKb - availKb);
        root.memory = ({
            total: totalKb,
            used: usedKb,
            pct: Math.max(0, Math.min(100, usedKb * 100 / totalKb)),
            swap_total: swapTotalKb / 1048576,
            swap_used: Math.max(0, swapTotalKb - swapFreeKb) / 1048576
        });
    }

    FileView {
        id: meminfo
        path: "/proc/meminfo"
        preload: true
        onLoaded: root.updateMemory(text())
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: meminfo.reload()
    }

    // ------------------------------------------------------------- hardware detection
    // Detect if backlight devices actually exist in /sys/class/backlight.
    Process {
        id: checkBacklight
        command: ["sh", "-c", "ls -A /sys/class/backlight 2>/dev/null | grep -q . && which brightnessctl >/dev/null 2>&1 && echo 1 || echo 0"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.hasBrightness = (text.trim() === "1")
        }
    }

    // Detect if wireless network hardware actually exists.
    Process {
        id: checkNmcli
        command: ["sh", "-c", "ls -d /sys/class/net/*/wireless 2>/dev/null | grep -q . || (which iw >/dev/null 2>&1 && iw dev 2>/dev/null | grep -q Interface) || (which nmcli >/dev/null 2>&1 && nmcli -t -f TYPE device 2>/dev/null | grep -q wifi) && echo 1 || echo 0"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.hasWifi = (text.trim() === "1")
        }
    }

    // Detect if bluetooth controller/adapter actually exists.
    Process {
        id: checkBtctl
        command: ["sh", "-c", "ls -A /sys/class/bluetooth 2>/dev/null | grep -q . || (which rfkill >/dev/null 2>&1 && rfkill list bluetooth 2>/dev/null | grep -q bluetooth) && echo 1 || echo 0"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.hasBluetooth = (text.trim() === "1")
        }
    }

    // Volume polling & control
    property real currentVolume: 0.5
    property bool isMuted: false

    Process {
        id: pollVolumeProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const s = text.trim();
                root.isMuted = s.indexOf("[MUTED]") !== -1;
                const match = s.match(/([0-9]+\.?[0-9]*)/);
                if (match && match[1]) {
                    const v = parseFloat(match[1]);
                    if (!isNaN(v)) root.currentVolume = Math.max(0.0, Math.min(1.5, v));
                }
            }
        }
    }

    function setVolume(val) {
        root.currentVolume = val;
        root.isMuted = false;
        root.run("wpctl", ["set-volume", "@DEFAULT_AUDIO_SINK@", val.toFixed(2)]);
    }

    function toggleMute() {
        root.isMuted = !root.isMuted;
        root.run("wpctl", ["set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]);
    }

    // Brightness polling & control
    property real currentBrightness: 1.0

    Process {
        id: pollBrightnessProc
        command: ["sh", "-c", "brightnessctl -m 2>/dev/null | head -n 1"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(",");
                if (parts.length >= 4) {
                    const pctStr = parts[3].replace("%", "").trim();
                    const pct = parseInt(pctStr, 10);
                    if (!isNaN(pct)) root.currentBrightness = Math.max(0.05, Math.min(1.0, pct / 100.0));
                }
            }
        }
    }

    function setBrightness(val) {
        root.currentBrightness = val;
        root.run("brightnessctl", ["set", Math.round(val * 100) + "%"]);
    }

    // WiFi scanning, connection & management
    property bool wifiEnabled: true
    property string wifiActiveSsid: ""
    property var wifiNetworks: []
    property bool wifiScanning: false
    property string wifiError: ""

    Process {
        id: scanWifiProc
        command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.wifiScanning = false;
                const lines = text.trim().split("\n");
                const nets = [];
                let active = "";
                const seen = {};
                for (let i = 0; i < lines.length; ++i) {
                    const line = lines[i].trim();
                    if (!line) continue;
                    const parts = line.split(":");
                    if (parts.length < 4) continue;
                    const inUse = parts[0].indexOf("*") !== -1;
                    const ssid = parts[1].trim();
                    if (!ssid || seen[ssid]) continue;
                    seen[ssid] = true;
                    const signal = parseInt(parts[2], 10) || 50;
                    const sec = parts[3].trim() || "OPEN";
                    if (inUse) active = ssid;
                    nets.push({ inUse: inUse, ssid: ssid, signal: signal, security: sec });
                }
                root.wifiActiveSsid = active;
                root.wifiNetworks = nets;
            }
        }
    }

    function scanWifi() {
        if (root.wifiScanning || scanWifiProc.running) return;
        root.wifiScanning = true;
        scanWifiProc.running = true;
    }

    function toggleWifi() {
        root.wifiEnabled = !root.wifiEnabled;
        root.run("nmcli", ["radio", "wifi", root.wifiEnabled ? "on" : "off"]);
        if (root.wifiEnabled) root.scanWifi();
    }

    function connectWifi(ssid, password) {
        root.wifiError = "";
        const args = ["device", "wifi", "connect", ssid];
        if (password && password.length > 0) {
            args.push("password", password);
        }
        root.run("nmcli", args);
        wifiRefreshTimer.restart();
    }

    function disconnectWifi(ssid) {
        root.run("nmcli", ["connection", "down", "id", ssid]);
        wifiRefreshTimer.restart();
    }

    Timer {
        id: wifiRefreshTimer
        interval: 3000
        repeat: false
        onTriggered: if (root.hasWifi) root.scanWifi()
    }

    // Bluetooth scanning, connection & management
    property bool btEnabled: true
    property var btDevices: []
    property bool btScanning: false

    Process {
        id: scanBtProc
        command: ["bluetoothctl", "devices"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.btScanning = false;
                const lines = text.trim().split("\n");
                const devs = [];
                for (let i = 0; i < lines.length; ++i) {
                    const l = lines[i].trim();
                    if (!l.startsWith("Device ")) continue;
                    const rest = l.substring(7);
                    const sp = rest.indexOf(" ");
                    if (sp === -1) continue;
                    const mac = rest.substring(0, sp);
                    const name = rest.substring(sp + 1);
                    devs.push({ mac: mac, name: name });
                }
                root.btDevices = devs;
            }
        }
    }

    function scanBluetooth() {
        if (root.btScanning || scanBtProc.running) return;
        root.btScanning = true;
        scanBtProc.running = true;
    }

    function toggleBluetooth() {
        root.btEnabled = !root.btEnabled;
        root.run("bluetoothctl", ["power", root.btEnabled ? "on" : "off"]);
        if (root.btEnabled) root.scanBluetooth();
    }

    function connectBluetooth(mac) {
        root.run("bluetoothctl", ["connect", mac]);
    }

    function disconnectBluetooth(mac) {
        root.run("bluetoothctl", ["disconnect", mac]);
    }

    // Read /etc/hacknetos/theme.cfg for admin-configurable default theme.
    FileView {
        id: themeCfgFile
        path: "/etc/hacknetos/theme.cfg"
        preload: true
        onLoaded: {
            var id = text().trim();
            if (id && Theme.palettes[id]) {
                root.themeCfg = id;
                if (Theme.themeId !== id) {
                    Theme.themeId = id;
                    Theme.themeChanged();
                }
            } else {
                root.themeCfg = "";
            }
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!checkBacklight.running) checkBacklight.running = true;
            if (!checkNmcli.running) checkNmcli.running = true;
            if (!checkBtctl.running) checkBtctl.running = true;
            if (!pollVolumeProc.running) pollVolumeProc.running = true;
            if (root.hasBrightness && !pollBrightnessProc.running) pollBrightnessProc.running = true;
        }
    }

    // Memory text
    function memoryText() {
        if (!memory || !memory.total) return "MEM --/--";
        return (memory.used / 1024 / 1024).toFixed(1) + " / " + (memory.total / 1024 / 1024).toFixed(1) + " GiB";
    }

    // Window management
    function activate(id) {
        run("hacknetctl", ["activate", String(id)]);
    }

    function kill(id) {
        run("hacknetctl", ["kill", String(id)]);
    }

    function cycle(delta) {
        run("hacknetctl", ["cycle", String(delta)]);
    }

    function setDnd(on) {
        root.dnd = !!on;
        run("hacknetctl", ["dnd", on ? "on" : "off"]);
    }

    function setTheme(id) {
        run("hacknetctl", ["theme", id]);
    }

    // Gutter visibility toggle
    function toggleGutter() {
        root.run("hacknetctl", ["toggle-gutter"]);
    }

    function netmapMove(id, x, y) {
        run("hacknetctl", ["netmap-move", String(id), String(Math.round(x)), String(Math.round(y))]);
    }

    function netmapReset() {
        run("hacknetctl", ["netmap-reset"]);
    }

    // Media controls
    function media(action) {
        run("hacknetctl", ["media", action]);
    }

    function volume(v) {
        run("hacknetctl", ["volume", String(v)]);
    }

    // Notification system
    function notify(summary, body) {
        run("notify-send", [summary, body]);
    }

    // Launch a program. Previously this only logged, which is why every button
    // in the shell appeared dead.
    function run(cmd, args) {
        const argv = [cmd].concat(args || []);
        try {
            Quickshell.execDetached(argv);
        } catch (e) {
            console.warn("hacknet: failed to run", argv.join(" "), e);
        }
    }

    // Called from Hyprland socket
    property var windowsList: []

    // Netmap node actions
    function activateNode(nodeId) {
        // The home node is synthesized in the shell (it is never in the
        // daemon's node list), so the "home" check must come before the
        // lookup — otherwise find() returns undefined and the click is
        // silently dropped.
        if (nodeId === "home") {
            // Return to deck 1 (the home/hacknet view).
            root.run("hacknetctl", ["cycle", "0"]);
            return;
        }
        const node = root.nodes.find(n => n.id === nodeId);
        if (!node) return;
        root.activate(nodeId);
    }

    // Virtual desktop management
    function addDesktop() {
        root.run("hacknetctl", ["desktop-add"]);
    }

    function removeDesktop(id) {
        if (root.desktopCount <= 1) return;
        root.run("hacknetctl", ["desktop-remove", String(id)]);
    }

    function switchDesktop(id) {
        if (id < 1 || id > root.desktopCount) return;
        root.run("hacknetctl", ["desktop-switch", String(id)]);
    }

    // Fullscreen management
    function setFullscreen(windowId, enable) {
        if (enable) {
            root.fullscreenWindow = windowId;
            root.fullscreenActive = true;
            root.run("hacknetctl", ["fullscreen", windowId, "true"]);
        } else {
            root.fullscreenWindow = null;
            root.fullscreenActive = false;
            root.run("hacknetctl", ["fullscreen", windowId, "false"]);
        }
    }
    
    // The daemon owns the flag and flips it; state sync updates the UI.
    function toggleTerminalBottomOnly() {
        root.run("hacknetctl", ["terminal-bottom", "true"]);
    }

    function showNodeContextMenu(nodeId, x, y) {
        const node = root.nodes.find(n => n.id === nodeId);
        if (!node) return;
        console.log("Context menu for node:", nodeId, "at", x, y);
        if (node.windowId) {
            console.log("Context menu for window:", node.windowId);
        }
    }
}
