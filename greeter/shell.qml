import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Greetd

ShellRoot {
    id: greeterShell

    Variants {
        model: Quickshell.screens
        delegate: Component {
            PanelWindow {
                id: greeterWindow
                required property var modelData
                screen: modelData
                anchors { top: true; left: true; right: true; bottom: true }
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
                WlrLayershell.namespace: "hacknet-greeter"
                color: "#040507"

                // Greeter State: default to "login" view to auto-jump on boot
                property string currentView: "login" // "login" or "prelogin"
                property bool settingsOpen: false
                property bool powerOpen: false
                property var detectedAccounts: []
                property string lastUser: ""
                property string savedLastUser: ""

                property string pendingUsername: ""
                property string pendingPassword: ""
                property bool fingerprintEnrolled: false
                property string bioMessage: ""
                property string authError: ""

                function saveLastUser(u) {
                    if (!u) return;
                    saveUserProc.command = ["sh", "-c", "printf '%s\\n' \"$1\" > /var/lib/greetd/last_user", "--", u];
                    saveUserProc.running = true;
                }

                function updateSelectedUser() {
                    if (greeterWindow.detectedAccounts.length === 0) return;

                    let selected = "";
                    if (greeterWindow.savedLastUser && greeterWindow.detectedAccounts.includes(greeterWindow.savedLastUser)) {
                        selected = greeterWindow.savedLastUser;
                    } else {
                        // Prioritize first real user (e.g. alice) over operator
                        const nonOperator = greeterWindow.detectedAccounts.filter(u => u !== "operator");
                        if (nonOperator.length > 0) {
                            selected = nonOperator[0];
                        } else {
                            selected = greeterWindow.detectedAccounts[0];
                        }
                    }

                    if (!greeterWindow.pendingUsername || !greeterWindow.detectedAccounts.includes(greeterWindow.pendingUsername)) {
                        greeterWindow.pendingUsername = selected;
                    }
                    greeterWindow.lastUser = selected;
                    checkFingerprint(greeterWindow.pendingUsername);
                    saveLastUser(greeterWindow.pendingUsername);
                }

                function checkFingerprint(user) {
                    if (!user) return;
                    fprintCheckProc.command = [
                        "sh", "-c",
                        'u="$1"; if [ -d "/var/lib/fprint/$u" ] && [ "$(ls -A "/var/lib/fprint/$u" 2>/dev/null)" ]; then echo yes; elif command -v fprintd-list >/dev/null 2>&1 && fprintd-list "$u" 2>/dev/null | grep -q "verify-finger"; then echo yes; else echo no; fi',
                        "--", user
                    ];
                    fprintCheckProc.running = true;
                }

                // Read saved last_user from /var/lib/greetd/last_user
                Process {
                    id: lastUserProc
                    command: ["sh", "-c", "cat /var/lib/greetd/last_user 2>/dev/null"]
                    running: true
                    stdout: SplitParser {
                        splitMarker: "\n"
                        onRead: (data) => {
                            const u = data.trim();
                            if (u) {
                                greeterWindow.savedLastUser = u;
                                greeterWindow.updateSelectedUser();
                            }
                        }
                    }
                }

                // Discover accounts from /etc/passwd
                Process {
                    id: userProc
                    command: ["sh", "-c", "awk -F: '$3 >= 1000 && $3 < 60000 && $1 != \"nobody\" && $1 != \"greeter\" && $1 != \"live\" {print $1}' /etc/passwd"]
                    running: true
                    stdout: SplitParser {
                        splitMarker: "\n"
                        onRead: (data) => {
                            const u = data.trim();
                            if (u) {
                                const list = greeterWindow.detectedAccounts.slice();
                                if (!list.includes(u)) {
                                    list.push(u);
                                    greeterWindow.detectedAccounts = list;
                                    greeterWindow.updateSelectedUser();
                                }
                            }
                        }
                    }
                }

                // Check fingerprint enrollment for active user
                Process {
                    id: fprintCheckProc
                    running: false
                    stdout: SplitParser {
                        splitMarker: "\n"
                        onRead: (data) => {
                            greeterWindow.fingerprintEnrolled = (data.trim() === "yes");
                            if (greeterWindow.fingerprintEnrolled) {
                                greeterWindow.bioMessage = "FINGERPRINT SENSOR READY // SCAN OR ENTER PASSWORD";
                            } else {
                                greeterWindow.bioMessage = "";
                            }
                        }
                    }
                }

                // Greetd Connections
                Connections {
                    target: Greetd

                    function onAuthMessage(message, error, responseRequired, echoResponse) {
                        const msgLower = (message || "").toLowerCase();
                        if (msgLower.includes("fingerprint") || msgLower.includes("fprint") || msgLower.includes("swipe") || msgLower.includes("place")) {
                            greeterWindow.fingerprintEnrolled = true;
                            greeterWindow.bioMessage = message;
                        }

                        if (responseRequired) {
                            Greetd.respond(greeterWindow.pendingPassword);
                        }
                    }

                    function onReadyToLaunch() {
                        saveUserProc.command = ["sh", "-c", "mkdir -p /var/lib/greetd && echo " + greeterWindow.pendingUsername + " > /var/lib/greetd/last_user"];
                        saveUserProc.running = true;
                        launchTimer.start();
                    }

                    function onAuthFailure(message) {
                        greeterWindow.authError = message || "Invalid credentials.";
                    }

                    function onError(error) {
                        greeterWindow.authError = error;
                    }
                }

                Process {
                    id: saveUserProc
                    running: false
                }

                Timer {
                    id: launchTimer
                    interval: 250
                    running: false
                    onTriggered: {
                        Greetd.launch(["/usr/bin/hacknet-hyprland"], [], true);
                    }
                }

                function startAuth(user, pass) {
                    greeterWindow.authError = "";
                    greeterWindow.pendingUsername = user;
                    greeterWindow.pendingPassword = pass;

                    if (Greetd.available) {
                        Greetd.createSession(user);
                    } else {
                        // Mock preview / dev mode
                        mockAuthTimer.start();
                    }
                }

                Timer {
                    id: mockAuthTimer
                    interval: 400
                    running: false
                    onTriggered: {
                        console.log("Mock auth success for user:", greeterWindow.pendingUsername);
                    }
                }

                // Authentic Hexagonal Wave Background
                HexBackground {
                    anchors.fill: parent
                }

                // Pre-Login View (reached via CANCEL from LoginView)
                PreLoginView {
                    id: preLoginView
                    anchors.fill: parent
                    opacity: greeterWindow.currentView === "prelogin" ? 1.0 : 0.0
                    visible: opacity > 0.01
                    lastUser: greeterWindow.lastUser || "alice"

                    Behavior on opacity {
                        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
                    }

                    onContinueClicked: {
                        greeterWindow.pendingUsername = greeterWindow.lastUser;
                        greeterWindow.currentView = "login";
                        loginView.resetFields();
                    }

                    onLoginClicked: {
                        greeterWindow.currentView = "login";
                        loginView.resetFields();
                    }

                    onSettingsClicked: {
                        greeterWindow.settingsOpen = true;
                    }

                    onExitClicked: {
                        greeterWindow.powerOpen = true;
                    }
                }

                // Login View (active by default on boot)
                LoginView {
                    id: loginView
                    anchors.fill: parent
                    opacity: greeterWindow.currentView === "login" ? 1.0 : 0.0
                    visible: opacity > 0.01
                    username: greeterWindow.pendingUsername
                    accountList: greeterWindow.detectedAccounts.length > 0 ? greeterWindow.detectedAccounts : ["alice"]
                    errorMessage: greeterWindow.authError
                    fingerprintConfigured: greeterWindow.fingerprintEnrolled
                    bioMessage: greeterWindow.bioMessage

                    Behavior on opacity {
                        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
                    }

                    onCancelClicked: {
                        if (Greetd.available) Greetd.cancelSession();
                        greeterWindow.currentView = "prelogin";
                        greeterWindow.authError = "";
                    }

                    onUserSelected: (user) => {
                        greeterWindow.pendingUsername = user;
                        greeterWindow.checkFingerprint(user);
                        greeterWindow.saveLastUser(user);
                        if (Greetd.available) {
                            Greetd.cancelSession();
                            Greetd.createSession(user);
                        }
                    }

                    onLoginRequested: (user, pass) => {
                        greeterWindow.startAuth(user, pass);
                    }
                }

                // Settings Modal
                SettingsModal {
                    anchors.fill: parent
                    visible: greeterWindow.settingsOpen
                    onBackClicked: greeterWindow.settingsOpen = false
                }

                // Power Modal
                PowerModal {
                    anchors.fill: parent
                    visible: greeterWindow.powerOpen
                    onCancelClicked: greeterWindow.powerOpen = false
                }
            }
        }
    }
}
