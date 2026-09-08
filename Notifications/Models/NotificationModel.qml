import QtQuick
import Quickshell.Services.Notifications
import "../../Theme"

// Owns the actual notification server connection and centralizes urgency
// label/color mapping.
QtObject {
    id: root

    readonly property NotificationServer server: NotificationServer {
        actionIconsSupported: false
        inlineReplySupported: false
        imageSupported: true
        bodyMarkupSupported: false

        onNotification: notification => {
            notification.tracked = true;
        }
    }

    readonly property var notifications: server.trackedNotifications

    function isDanger(urgency) {
        return urgency === NotificationUrgency.Critical;
    }

    function urgencyLabel(urgency) {
        return root.isDanger(urgency) ? "DANGER" : "NOMINAL";
    }

    function urgencyColor(urgency) {
        return root.isDanger(urgency) ? Colors.dangerAccent : Colors.nominalAccent;
    }
}
