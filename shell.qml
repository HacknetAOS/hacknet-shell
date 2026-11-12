// HacknetOS shell entrypoint (Quickshell 0.3).
//
// Imports are relative on purpose: the shell is installed as a plain directory
// tree, not as an installed QML module, so "Hacknet.Components" style imports
// fail at runtime with 'module is not installed'.
import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "singletons"
import "components"

ShellRoot {
    // Notification daemon: without this, notify-send has no server on Wayland.
    NotificationServer {
        id: notificationServer
        keepOnReload: true
        onNotification: (notification) => {
            Notifs.push(notification.appName, notification.summary, notification.body, notification.urgency);
            notification.tracked = true;
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: Component {
            ScreenRoot { screen: modelData }
        }
    }
}
