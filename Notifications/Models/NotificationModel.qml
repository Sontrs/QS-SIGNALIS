import QtQuick
import Quickshell.Services.Notifications
import "../../Theme"

// Owns the actual notification server connection and centralizes urgency
// label/color mapping — the old project had two separate, half-finished
// copies of this logic (NotifMod.qml called urgencyLabel()/urgencyColor()
// without ever defining them; only NotifTest.qml had working copies). One
// source of truth here instead.
QtObject {
    id: root

    readonly property NotificationServer server: NotificationServer {
        actionIconsSupported: false
        inlineReplySupported: false
        imageSupported: true
        bodyMarkupSupported: false

        // Without this, every incoming notification is silently discarded —
        // the server does NOT add notifications to trackedNotifications
        // automatically. Per the docs: "If this notification should not be
        // discarded, set its tracked property to true." This is why nothing
        // was showing up despite notify-send succeeding with no errors.
        onNotification: notification => {
            notification.tracked = true;
        }
    }

    readonly property var notifications: server.trackedNotifications

    // A single explicit comparison against Critical rather than a 3-way
    // switch — Low and Normal both read as NOMINAL (routine notifications,
    // almost always sent as Normal urgency by default, should look calm
    // rather than CAUTION). Also sidesteps whatever was causing only 2 of
    // 3 switch branches to actually match in practice.
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
