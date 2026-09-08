import QtQuick
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../../Theme"
import "../../Components/Popups" as Popups

// SystemTray is a singleton — merely referencing it starts Quickshell
// tracking real tray contents; no explicit "start" call needed. `items`
// is a Quickshell ObjectModel<SystemTrayItem>, fed straight into the
// Repeater below exactly like NotificationList already does with
// trackedNotifications — model item lands on the delegate's own
// `modelData`, no separate role wiring required.
//
// Each delegate is deliberately bare — a hover-tinted square holding one
// icon, no label. Every reference tray (waybar's own module included)
// treats the icon as the whole control; there's nothing meaningful to
// put in a text label here.
//
// IconImage (Quickshell.Widgets) is used over a plain Image because it's
// purpose-built for this — SystemTrayItem.icon's docs call it "usable as
// an Image source", and IconImage's own docs list "System tray icons" as
// a named intended use case.
//
// Click routing follows the StatusNotifierItem spec as Quickshell exposes
// it: left click -> activate() (the item's primary action), middle click
// -> secondaryActivate(), right click -> display(), which is the spec's
// own ContextMenu(x, y) call — it asks the app to show its own native
// menu at that position, whatever that app's menu actually looks like.
// That's deliberate, not a shortcut: some apps (Steam being the obvious
// one) render their own themed menu regardless of what a shell tries to
// draw, so QsMenuAnchor rendering a shell-owned popup was never going to
// look consistent across every app anyway — and a Quickshell issue
// tracker report ties a real crash specifically to QsMenuAnchor's
// internal handling of one of the menu types some tray apps use
// (PlatformMenuEntry), which display() sidesteps entirely by handing the
// job straight to the app itself. onlyMenu items (no real activate
// action — menu only) route left click through display() too, since
// activate() on those "will do nothing" per the docs.
//
// No hasMenu gate before calling display() — nothing in the docs
// suggests it's unsafe to call on an item with no menu, and gating on it
// risks silently eating right-clicks on apps where hasMenu doesn't
// accurately reflect what the app will actually do with ContextMenu(x,
// y). Worth confirming live that this doesn't misfire on an item with
// genuinely no menu at all.
//
// NeedsAttention gets a dim danger-accent tint, reusing the same
// severity token Battery/NotificationPopup already use rather than
// inventing a new one. Passive and Active both render identically —
// waybar's own tray never distinguished them either, no reason to start
// now.
Row {
    id: root

    required property QtObject window

    spacing: Metrics.sizeTiny

    Repeater {
        model: SystemTray.items

        Rectangle {
            id: trayIcon
            required property var modelData

            width: 24
            height: 24
            color: {
                if (trayIcon.modelData.status === Status.NeedsAttention)
                    return Qt.rgba(Colors.dangerAccent.r, Colors.dangerAccent.g, Colors.dangerAccent.b, 0.25);
                return mouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent";
            }

            Behavior on color {
                ColorAnimation {
                    duration: Metrics.animFast
                    easing.type: Easing.OutQuad
                }
            }

            IconImage {
                anchors.centerIn: parent
                implicitSize: Metrics.iconSmall
                source: trayIcon.modelData.icon
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton) {
                        const pos = trayIcon.mapToItem(root.window.contentItem, mouse.x, mouse.y);
                        trayIcon.modelData.display(root.window, pos.x, pos.y);
                    } else if (mouse.button === Qt.MiddleButton) {
                        trayIcon.modelData.secondaryActivate();
                    } else if (trayIcon.modelData.onlyMenu) {
                        const pos = trayIcon.mapToItem(root.window.contentItem, mouse.x, mouse.y);
                        trayIcon.modelData.display(root.window, pos.x, pos.y);
                    } else {
                        trayIcon.modelData.activate();
                    }
                }

                // angleDelta is in eighths of a degree, positive =
                // away from user (scroll up / scroll left). Sign
                // flipped here since scroll()'s `delta` follows the
                // StatusNotifierItem convention of positive = towards
                // the user, the opposite of Qt's own wheel event.
                onWheel: event => {
                    const horizontal = event.angleDelta.y === 0;
                    const raw = horizontal ? event.angleDelta.x : event.angleDelta.y;
                    trayIcon.modelData.scroll(-raw, horizontal);
                }
            }

            // tooltipTitle/tooltipDescription come straight from the SNI
            // ToolTip property, which plenty of apps just never set —
            // falls back to title, then id (the one field that's
            // effectively always present, usually the app's own name),
            // rather than showing an empty tooltip when that happens.
            Popups.Tooltip {
                hoverTarget: trayIcon
                hovered: mouseArea.containsMouse

                Column {
                    spacing: Metrics.sizeTiny

                    Text {
                        text: trayIcon.modelData.tooltipTitle || trayIcon.modelData.title || trayIcon.modelData.id
                        color: Colors.textPrimary
                        font.family: Fonts.currentFamily
                        font.pixelSize: Fonts.small
                    }
                    Text {
                        visible: trayIcon.modelData.tooltipDescription !== ""
                        text: trayIcon.modelData.tooltipDescription
                        color: Colors.textPrimary
                        font.family: Fonts.currentFamily
                        font.pixelSize: Fonts.small
                        wrapMode: Text.WordWrap
                        width: Math.min(implicitWidth, 240)
                    }
                }
            }
        }
    }
}
