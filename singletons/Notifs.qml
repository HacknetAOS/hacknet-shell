pragma Singleton

import QtQuick
import Quickshell

// In-memory notification store for the message history panel and popup.
Singleton {
    id: root

    property var notifications: []
    property bool popupOpen: false
    property var popupData: null

    function push(app, title, body, urgency) {
        // Debug: confirm what the NotificationServer actually delivered.
        console.log("Notifs.push app=" + JSON.stringify(app)
                    + " title=" + JSON.stringify(title)
                    + " body=" + JSON.stringify(body)
                    + " urgency=" + JSON.stringify(urgency));
        const now = new Date();
        const pad = (n) => (n < 10 ? "0" + n : "" + n);
        const item = {
            app: app || "",
            title: title || "",
            body: body || "",
            urgency: String(urgency || "normal"),
            time: now,
            // Pre-formatted so delegates never call Qt.formatTime on a JS Date.
            timeText: pad(now.getHours()) + ":" + pad(now.getMinutes())
                      + ":" + pad(now.getSeconds())
        };
        const list = root.notifications.slice();
        list.unshift(item);
        root.notifications = list.slice(0, 50);
        root.popupData = item;
        root.popupOpen = !Daemon.dnd;
    }

    function clear() {
        root.notifications = [];
        root.popupOpen = false;
        root.popupData = null;
    }
}
