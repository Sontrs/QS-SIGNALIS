import QtQuick
import Quickshell.Services.Notifications
import "../Components/Cards" as Cards
import "../Models" as Models
import "../../Theme"

ListView {
    id: root

    spacing: Metrics.sizeMedium
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    property var notificationModel: Models.NotificationModel {}

    // Quickshell's trackedNotifications prints UntypedObjectModel based on logs.
    // It doesn't expose a `count` property to QML, but it does expose
    // `values`, whose length tracks the number of notifications.
    readonly property int notificationCount:
        notificationModel.notifications.values.length

    // Fallback duration when a notification doesn't specify a real timeout.
    // Per the freedesktop spec, expireTimeout of -1 (or 0) means "the
    // server/client should pick a sensible default" — it does NOT mean
    // "expire immediately" or "never expire", so that has to be handled
    // explicitly below rather than used as-is.
    property int defaultTimeoutMs: 6000

    model: root.notificationModel.notifications

    // One-shot entrance/exit motion (not a continuous/looping effect) —
    // addresses cards just snapping into and out of existence. Easy to
    // remove if you'd rather have zero motion for now.
    add: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Metrics.animNormal }
        NumberAnimation { property: "x"; from: 40; to: 0; duration: Metrics.animNormal; easing.type: Easing.OutQuad }
    }
    remove: Transition {
        NumberAnimation { property: "opacity"; to: 0; duration: Metrics.animFast }
    }
    displaced: Transition {
        NumberAnimation { properties: "y"; duration: Metrics.animNormal; easing.type: Easing.OutQuad }
    }

    delegate: Item {
        id: delegateItem
        required property var modelData
        readonly property var notification: modelData

        width: ListView.view ? ListView.view.width : root.width
        height: card.height

        Cards.NotificationCard {
            id: card
            anchors.left: parent.left
            anchors.right: parent.right

            appName: delegateItem.notification.appName
            summary: delegateItem.notification.summary
            body: delegateItem.notification.body
            urgencyText: root.notificationModel.urgencyLabel(delegateItem.notification.urgency)
            urgencyColor: root.notificationModel.urgencyColor(delegateItem.notification.urgency)

            TapHandler {
                acceptedButtons: Qt.LeftButton
                onTapped: delegateItem.notification.dismiss()
            }
        }

        Timer {
            // Critical notifications persist until manually dismissed —
            // matches how most notification systems avoid silently
            // clearing your most urgent alerts.
            running: delegateItem.notification.urgency !== NotificationUrgency.Critical
            interval: delegateItem.notification.expireTimeout > 0
                      ? delegateItem.notification.expireTimeout * 1000
                      : root.defaultTimeoutMs
            onTriggered: delegateItem.notification.expire()
        }
    }


}
