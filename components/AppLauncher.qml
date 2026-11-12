import QtQuick
import Quickshell
import Quickshell.Io
import "../singletons"

Rectangle {
    id: root
    implicitWidth: 680
    implicitHeight: 520

    color: "#0b0d13"
    border.width: 1
    border.color: Theme.accent

    // Public focus target
    function forceActiveFocus() {
        searchField.focus = true;
        searchField.forceActiveFocus();
        focusTimer.restart();
    }

    Timer {
        id: focusTimer
        interval: 50
        repeat: false
        onTriggered: {
            searchField.focus = true;
            searchField.forceActiveFocus();
        }
    }

    Connections {
        target: Ui
        function onLauncherOpenChanged() {
            if (Ui.launcherOpen) {
                searchField.text = "";
                root.query = "";
                root.selectedIndex = 0;
                root.fileResults = [];
                root.updateResults();
                searchField.focus = true;
                searchField.forceActiveFocus();
                focusTimer.restart();
            }
        }
    }

    // State
    property string query: ""
    property int selectedIndex: 0
    property var allApps: []
    property var fileResults: []
    property var filteredResults: []

    // Built-in system actions and commands
    readonly property var systemActions: [
        {
            type: "action",
            badge: "[SYSTEM]",
            badgeColor: Theme.alert,
            title: "Shut Down",
            desc: "Power off the system (systemctl poweroff)",
            icon: "system-shutdown",
            keywords: "shutdown poweroff halt turn off stop power",
            action: function() { Ui.closeAll(); Daemon.run("sudo", ["-n", "systemctl", "poweroff"]); }
        },
        {
            type: "action",
            badge: "[SYSTEM]",
            badgeColor: Theme.alert,
            title: "Reboot",
            desc: "Restart the operating system (systemctl reboot)",
            icon: "system-reboot",
            keywords: "reboot restart reset boot",
            action: function() { Ui.closeAll(); Daemon.run("sudo", ["-n", "systemctl", "reboot"]); }
        },
        {
            type: "action",
            badge: "[SYSTEM]",
            badgeColor: Theme.fg,
            title: "Lock Session",
            desc: "Lock screen with Hacknet security overlay",
            icon: "system-lock-screen",
            keywords: "lock lockscreen secure protect session",
            action: function() { Ui.lockSession(); }
        },
        {
            type: "action",
            badge: "[SYSTEM]",
            badgeColor: Theme.alert,
            title: "Log Out",
            desc: "Terminate current desktop session",
            icon: "system-log-out",
            keywords: "logout exit signout sign out quit",
            action: function() { Ui.closeAll(); Daemon.run("loginctl", ["terminate-user", Daemon.username]); }
        },
        {
            type: "action",
            badge: "[SYSTEM]",
            badgeColor: Theme.dim,
            title: "Suspend",
            desc: "Put the system into low-power sleep mode",
            icon: "system-suspend",
            keywords: "sleep suspend standby hibernate",
            action: function() { Ui.closeAll(); Daemon.run("systemctl", ["suspend"]); }
        },
        {
            type: "action",
            badge: "[DESKTOP]",
            badgeColor: Theme.accent,
            title: "Control Center / Settings",
            desc: "Open display, audio, network, and theme settings",
            icon: "preferences-system",
            keywords: "settings control center config preferences options display audio network",
            action: function() { Ui.closeAll(); Ui.toggleSettings(); }
        },
        {
            type: "action",
            badge: "[DESKTOP]",
            badgeColor: Theme.accent,
            title: "Open Dock Terminal",
            desc: "Spawn a new terminal slot in the left dock column",
            icon: "utilities-terminal",
            keywords: "dock terminal slot netmap node term foot left",
            action: function() { Ui.closeAll(); Daemon.run("hacknet-dock-term", []); }
        },
        {
            type: "action",
            badge: "[DESKTOP]",
            badgeColor: Theme.accent,
            title: "Open Stage Terminal",
            desc: "Open a full terminal in the center DISPLAY stage",
            icon: "utilities-terminal",
            keywords: "terminal stage foot bash console shell command fastfetch",
            action: function() { Ui.closeAll(); Daemon.run("hacknet-term", ["--app-id", "hacknet-stage", "-e", "bash", "-lc", "fastfetch; exec bash"]); }
        },
        {
            type: "action",
            badge: "[DESKTOP]",
            badgeColor: Theme.accent,
            title: "Toggle RAM Gutter",
            desc: "Show or hide the left RAM meter dock",
            icon: "view-sidebar",
            keywords: "gutter ram sidebar toggle hide show memory",
            action: function() { Ui.closeAll(); Daemon.run("hacknetctl", ["toggle-gutter"]); }
        },
        {
            type: "theme",
            badge: "[THEME]",
            badgeColor: "#4169e1",
            title: "Theme: Blue (Default)",
            desc: "Apply authentic Hacknet Blue color palette",
            icon: "color-management",
            keywords: "theme blue default color palette style",
            action: function() { Ui.closeAll(); Daemon.run("hacknet-theme", ["apply", "blue"]); }
        },
        {
            type: "theme",
            badge: "[THEME]",
            badgeColor: "#e63946",
            title: "Theme: Hellhound",
            desc: "Apply aggressive crimson/amber security theme",
            icon: "color-management",
            keywords: "theme hellhound red crimson amber color palette style",
            action: function() { Ui.closeAll(); Daemon.run("hacknet-theme", ["apply", "hellhound"]); }
        },
        {
            type: "theme",
            badge: "[THEME]",
            badgeColor: "#00f0ff",
            title: "Theme: Ente",
            desc: "Apply vibrant cyan/teal telemetry theme",
            icon: "color-management",
            keywords: "theme ente cyan teal color palette style",
            action: function() { Ui.closeAll(); Daemon.run("hacknet-theme", ["apply", "ente"]); }
        },
        {
            type: "theme",
            badge: "[THEME]",
            badgeColor: "#00ff66",
            title: "Theme: Naix",
            desc: "Apply hacker matrix emerald green theme",
            icon: "color-management",
            keywords: "theme naix green matrix emerald color palette style",
            action: function() { Ui.closeAll(); Daemon.run("hacknet-theme", ["apply", "naix"]); }
        },
        {
            type: "theme",
            badge: "[THEME]",
            badgeColor: "#f0f0f0",
            title: "Theme: White",
            desc: "Apply clean monochrome forensic lab theme",
            icon: "color-management",
            keywords: "theme white mono monochrome light color palette style",
            action: function() { Ui.closeAll(); Daemon.run("hacknet-theme", ["apply", "white"]); }
        }
    ]

    // Default pre-seeded apps in case dynamic scan is loading
    readonly property var defaultApps: [
        { name: "Terminal", comment: "Foot terminal emulator", exec: "foot", icon: "utilities-terminal", keywords: "term console shell bash foot terminal" },
        { name: "File Manager", comment: "Thunar file manager", exec: "thunar", icon: "system-file-manager", keywords: "files folders explorer thunar disk storage" },
        { name: "Nano", comment: "CLI text editor", exec: "foot nano", icon: "text-editor", keywords: "nano edit text editor code cli" },
        { name: "Vim", comment: "Vi IMproved text editor", exec: "foot vim", icon: "text-editor", keywords: "vim vi edit text editor code" },
        { name: "HTOP", comment: "Interactive process viewer", exec: "foot htop", icon: "utilities-system-monitor", keywords: "htop top process task manager cpu ram monitor" },
        { name: "BTOP", comment: "Resource monitor", exec: "foot btop", icon: "utilities-system-monitor", keywords: "btop top process task monitor cpu ram system" },
        { name: "Fastfetch", comment: "System information tool", exec: "foot bash -lc 'fastfetch; exec bash'", icon: "system-search", keywords: "fastfetch neofetch sysinfo system hardware specs" },
        { name: "Media Player", comment: "MPV media player", exec: "mpv --player-operation-mode=pseudo-gui --", icon: "multimedia-video-player", keywords: "mpv video music media player sound" },
        { name: "Yay AUR Helper", comment: "Arch User Repository package manager", exec: "foot bash -lc 'yay; exec bash'", icon: "system-software-install", keywords: "yay aur pacman package install update software repo" }
    ]

    // Dynamically load apps
    Process {
        id: appScanner
        command: ["hacknet-apps"]
        stdout: StdioCollector {
            onTextChanged: {
                if (!text || text.length === 0) return;
                try {
                    let parsed = JSON.parse(text);
                    if (Array.isArray(parsed) && parsed.length > 0) {
                        root.allApps = parsed;
                        root.updateResults();
                    }
                } catch (e) {
                    // Fall back to defaultApps
                }
            }
        }
    }

    // File search process
    Process {
        id: fileSearcher
        property string pendingQuery: ""
        command: ["sh", "-c", "find \"$HOME\" -maxdepth 3 -iname \"*" + pendingQuery.replace(/["\\]/g, "") + "*\" ! -path \"*/.*\" 2>/dev/null | head -6"]
        stdout: StdioCollector {
            onTextChanged: {
                if (!text) return;
                let lines = text.split("\n");
                let files = [];
                for (let i = 0; i < lines.length; i++) {
                    let line = lines[i].trim();
                    if (line.length > 0) {
                        let parts = line.split("/");
                        let fname = parts[parts.length - 1];
                        files.push({ name: fname, path: line });
                    }
                }
                root.fileResults = files;
                root.updateResults();
            }
        }
    }

    Timer {
        id: fileSearchDebounce
        interval: 120
        repeat: false
        onTriggered: {
            let q = root.query.trim();
            if (q.length >= 2) {
                fileSearcher.pendingQuery = q;
                fileSearcher.running = true;
            } else {
                root.fileResults = [];
                root.updateResults();
            }
        }
    }

    Component.onCompleted: {
        root.allApps = root.defaultApps;
        appScanner.running = true;
        root.updateResults();
    }

    onVisibleChanged: {
        if (visible) {
            searchField.text = "";
            root.query = "";
            root.selectedIndex = 0;
            root.fileResults = [];
            root.updateResults();
            searchField.forceActiveFocus();
            if (!appScanner.running && root.allApps.length <= root.defaultApps.length) {
                appScanner.running = true;
            }
        }
    }

    function updateResults() {
        let q = root.query.trim().toLowerCase();
        let res = [];

        if (q.length === 0) {
            // Default view: popular apps & quick actions
            for (let i = 0; i < root.allApps.length && i < 6; i++) {
                let a = root.allApps[i];
                res.push({
                    type: "app",
                    badge: "[APP]",
                    badgeColor: Theme.accent,
                    title: a.name,
                    desc: a.comment || a.exec,
                    action: (function(execCmd) {
                        return function() { Ui.closeAll(); Quickshell.execDetached(["sh", "-c", execCmd]); };
                    })(a.exec)
                });
            }
            for (let j = 0; j < root.systemActions.length && j < 4; j++) {
                res.push(root.systemActions[j]);
            }
            root.filteredResults = res;
            if (root.selectedIndex >= res.length) root.selectedIndex = 0;
            return;
        }

        // 1. Search system actions
        for (let sa of root.systemActions) {
            let score = 0;
            let titleLower = sa.title.toLowerCase();
            let kw = sa.keywords || "";
            if (titleLower === q) score += 60;
            else if (titleLower.startsWith(q)) score += 35;
            else if (titleLower.includes(q)) score += 20;

            if (kw.includes(q)) score += 25;
            if (sa.desc.toLowerCase().includes(q)) score += 5;

            if (score > 0) {
                let item = Object.assign({}, sa);
                item.score = score;
                res.push(item);
            }
        }

        // 2. Search applications
        for (let a of root.allApps) {
            let score = 0;
            let nameLower = (a.name || "").toLowerCase();
            let commentLower = (a.comment || "").toLowerCase();
            let kwLower = (a.keywords || "").toLowerCase();
            let execLower = (a.exec || "").toLowerCase();

            if (nameLower === q) score += 50;
            else if (nameLower.startsWith(q)) score += 30;
            else if (nameLower.includes(q)) score += 15;

            if (kwLower.includes(q)) score += 12;
            if (execLower.includes(q)) score += 10;
            if (commentLower.includes(q)) score += 4;

            if (score > 0) {
                res.push({
                    type: "app",
                    badge: "[APP]",
                    badgeColor: Theme.accent,
                    title: a.name,
                    desc: a.comment || a.exec,
                    score: score,
                    action: (function(execCmd) {
                        return function() { Ui.closeAll(); Quickshell.execDetached(["sh", "-c", execCmd]); };
                    })(a.exec)
                });
            }
        }

        // Sort scored items descending
        res.sort(function(a, b) { return (b.score || 0) - (a.score || 0); });

        // 3. Search files
        for (let f of root.fileResults) {
            res.push({
                type: "file",
                badge: "[FILE]",
                badgeColor: Theme.dim,
                title: f.name,
                desc: f.path,
                action: (function(filePath) {
                    return function() { Ui.closeAll(); Quickshell.execDetached(["xdg-open", filePath]); };
                })(f.path)
            });
        }

        // 4. Fallback execution options
        res.push({
            type: "cmd",
            badge: "[TERM]",
            badgeColor: Theme.fg,
            title: "Run in terminal: " + q,
            desc: "Launch inside foot terminal",
            action: (function(cmdStr) {
                return function() { Ui.closeAll(); Quickshell.execDetached(["foot", "bash", "-lc", cmdStr + "; exec bash"]); };
            })(q)
        });
        res.push({
            type: "cmd",
            badge: "[EXEC]",
            badgeColor: Theme.fg,
            title: "Execute command: " + q,
            desc: "Run process in background",
            action: (function(cmdStr) {
                return function() { Ui.closeAll(); Quickshell.execDetached(["sh", "-c", cmdStr]); };
            })(q)
        });

        root.filteredResults = res;
        if (root.selectedIndex >= res.length) root.selectedIndex = 0;
    }

    function executeSelected() {
        if (root.filteredResults.length > 0 && root.selectedIndex >= 0 && root.selectedIndex < root.filteredResults.length) {
            let item = root.filteredResults[root.selectedIndex];
            if (item && typeof item.action === "function") {
                item.action();
            }
        }
    }

    // Top Header
    Rectangle {
        id: header
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: 28
        color: "#07080d"

        Text {
            anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
            text: "HACKNET // APPLICATION & COMMAND OPENER"
            color: Theme.accent
            font.family: Theme.mono
            font.pixelSize: Math.max(9, Theme.monoPx - 2)
            font.letterSpacing: 1
            font.bold: true
        }

        Text {
            anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
            text: "[ESC] CANCEL"
            color: Theme.dim
            font.family: Theme.mono
            font.pixelSize: Math.max(8, Theme.monoPx - 3)
            font.letterSpacing: 1
        }

        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: 1
            color: Theme.borderDim
        }
    }

    // Search Input Bar
    Rectangle {
        id: searchBox
        anchors { left: parent.left; right: parent.right; top: header.bottom; margins: 12 }
        height: 40
        color: "#10131c"
        border.width: 1
        border.color: searchField.activeFocus ? Theme.accent : Theme.borderDim

        MouseArea {
            anchors.fill: parent
            onClicked: {
                searchField.focus = true;
                searchField.forceActiveFocus();
            }
        }

        Text {
            id: prompt
            anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
            text: ">"
            color: Theme.accent
            font.family: Theme.mono
            font.pixelSize: Math.round(16 * Geo.scale)
            font.bold: true
        }

        TextInput {
            id: searchField
            focus: true
            anchors {
                left: prompt.right
                right: parent.right
                leftMargin: 10
                rightMargin: 12
                verticalCenter: parent.verticalCenter
            }
            color: "#ffffff"
            font.family: Theme.mono
            font.pixelSize: Math.round(14 * Geo.scale)
            cursorVisible: activeFocus
            cursorDelegate: Rectangle {
                width: 2
                color: Theme.accent
                visible: searchField.activeFocus
            }
            selectByMouse: true

            onTextChanged: {
                root.query = text;
                root.selectedIndex = 0;
                root.updateResults();
                fileSearchDebounce.restart();
            }

            Keys.onDownPressed: {
                if (root.filteredResults.length > 0) {
                    root.selectedIndex = (root.selectedIndex + 1) % root.filteredResults.length;
                    resultsList.positionViewAtIndex(root.selectedIndex, ListView.Contain);
                }
            }
            Keys.onUpPressed: {
                if (root.filteredResults.length > 0) {
                    root.selectedIndex = (root.selectedIndex - 1 + root.filteredResults.length) % root.filteredResults.length;
                    resultsList.positionViewAtIndex(root.selectedIndex, ListView.Contain);
                }
            }
            Keys.onReturnPressed: root.executeSelected()
            Keys.onEnterPressed: root.executeSelected()
            Keys.onEscapePressed: Ui.closeAll()
        }

        Text {
            anchors {
                left: prompt.right
                leftMargin: 10
                verticalCenter: parent.verticalCenter
            }
            text: "Search applications, files, commands, actions (e.g. shutdown, foot, btop)..."
            color: "#555b6e"
            font.family: Theme.mono
            font.pixelSize: Math.round(13 * Geo.scale)
            visible: searchField.text.length === 0
        }
    }

    // Results List
    ListView {
        id: resultsList
        anchors {
            left: parent.left
            right: parent.right
            top: searchBox.bottom
            bottom: footer.top
            leftMargin: 12
            rightMargin: 12
            topMargin: 8
            bottomMargin: 8
        }
        clip: true
        model: root.filteredResults
        spacing: 4

        delegate: Rectangle {
            id: row
            width: resultsList.width
            height: 48
            color: (index === root.selectedIndex) ? Theme.alpha(Theme.accent, 0.22) : (mouseArea.containsMouse ? "#141724" : "#0d1017")
            border.width: 1
            border.color: (index === root.selectedIndex) ? Theme.accent : Theme.borderDim

            // Selection indicator bar
            Rectangle {
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                width: 3
                color: (index === root.selectedIndex) ? Theme.accent : "transparent"
            }

            // Category Badge
            Rectangle {
                id: badgeBox
                anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                width: Math.max(54, badgeText.implicitWidth + 10)
                height: 22
                color: Theme.alpha(modelData.badgeColor || Theme.accent, 0.15)
                border.width: 1
                border.color: modelData.badgeColor || Theme.accent

                Text {
                    id: badgeText
                    anchors.centerIn: parent
                    text: modelData.badge || "[APP]"
                    color: modelData.badgeColor || Theme.accent
                    font.family: Theme.mono
                    font.pixelSize: Math.max(8, Theme.monoPx - 3)
                    font.bold: true
                }
            }

            // Title & Description
            Column {
                anchors {
                    left: badgeBox.right
                    right: enterHint.left
                    leftMargin: 12
                    rightMargin: 8
                    verticalCenter: parent.verticalCenter
                }
                spacing: 2

                Text {
                    text: modelData.title || ""
                    color: (index === root.selectedIndex) ? "#ffffff" : "#c9ccd3"
                    font.family: Theme.mono
                    font.pixelSize: Math.max(11, Theme.monoPx)
                    font.bold: index === root.selectedIndex
                    elide: Text.ElideRight
                    width: parent.width
                }

                Text {
                    text: modelData.desc || ""
                    color: (index === root.selectedIndex) ? Theme.fg : Theme.dim
                    font.family: Theme.mono
                    font.pixelSize: Math.max(9, Theme.monoPx - 2)
                    elide: Text.ElideRight
                    width: parent.width
                }
            }

            // Enter key hint for selected item
            Text {
                id: enterHint
                anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                text: "ENTER ↵"
                color: Theme.accent
                font.family: Theme.mono
                font.pixelSize: Math.max(8, Theme.monoPx - 3)
                font.bold: true
                visible: index === root.selectedIndex
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    root.selectedIndex = index;
                    root.executeSelected();
                }
            }
        }
    }

    // Bottom Footer / Help Bar
    Rectangle {
        id: footer
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 26
        color: "#07080d"

        Rectangle {
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: 1
            color: Theme.borderDim
        }

        Row {
            anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
            spacing: 16

            Text {
                text: "↑↓ NAVIGATE"
                color: Theme.dim
                font.family: Theme.mono
                font.pixelSize: Math.max(8, Theme.monoPx - 3)
            }
            Text {
                text: "↵ EXECUTE"
                color: Theme.dim
                font.family: Theme.mono
                font.pixelSize: Math.max(8, Theme.monoPx - 3)
            }
            Text {
                text: "ESC CLOSE"
                color: Theme.dim
                font.family: Theme.mono
                font.pixelSize: Math.max(8, Theme.monoPx - 3)
            }
        }

        Text {
            anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
            text: root.filteredResults.length + " ITEMS"
            color: Theme.accent
            font.family: Theme.mono
            font.pixelSize: Math.max(8, Theme.monoPx - 3)
            font.bold: true
        }
    }
}
