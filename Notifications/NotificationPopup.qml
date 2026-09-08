import QtQuick
import Quickshell
import Quickshell.Wayland
import "./Modules" as Modules
import "../Components/Frames" as Frames
import "../Theme"
import "../Theme/Effects" as Effects

PanelWindow {
    id: root

    implicitWidth: Metrics.notificationCardWidth + Metrics.sizeXLarge * 2

    // Starts small and grows with content rather than always claiming the
    // full screen height. Capped at a fraction of the actual screen height
    // so a long list scrolls within the popup instead of the window itself
    // growing without bound. root.screen can briefly be unset during
    // startup, same startup-race lesson learned from the earlier Wayland
    // "Invalid size" crash — guard against that rather than assume it's
    // already valid.
    readonly property real maxListHeight: (root.screen ? root.screen.height : 800) * 0.6
    readonly property real listHeight: Math.min(notificationList.contentHeight, root.maxListHeight)

    implicitHeight: topBar.height + root.listHeight
                    + (notificationList.notificationCount > 0 ? Metrics.sizeMedium * 2 : Metrics.sizeMedium)

    // Only shown while there's actually something to show — this is plain
    // data-driven visibility (the notification list's own count), not
    // something that needs IPC/keybind wiring. IPC is for things with no
    // other signal, like "open the launcher on a keypress"; this already
    // has a perfectly good signal in the server's own tracked-notification
    // count.
    visible: notificationList.notificationCount > 0

    color: "transparent"

    exclusionMode: ExclusionMode.Ignore

    // No anchors.bottom — that would stretch the window to fill the full
    // top-to-bottom span regardless of implicitHeight. Only pinning the
    // top-right corner lets it size itself to implicitHeight and grow
    // downward from there instead.
    anchors {
        top: true
        right: true
    }

    margins {
        top: Metrics.sizeXLarge
        right: Metrics.sizeXLarge
    }

    // === Main content (sampled by the CRT stack below) — needs its own
    // wrapping Item now that CRTStack always needs a sourceItem to sample,
    // not just when curvature is on. Same mainContent pattern AppLauncher
    // and WLogout already use. ===
    Item {
        id: mainContent
        anchors.fill: parent

        Frames.CutFrame {
            anchors.fill: parent
            strokeColor: Colors.redAccent
            fillColor: Colors.bgBase
        }

        Rectangle {
            id: topBar
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: Metrics.notificationPopupHeaderHeight
            color: Colors.redAccent

            Text {
                anchors.centerIn: parent
                text: "STATUS"
                font.family: Fonts.currentFamily
                font.bold: true
                font.pixelSize: Fonts.body
                color: Colors.bgBase
            }
        }

        Modules.NotificationList {
            id: notificationList
            anchors.top: topBar.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Metrics.sizeMedium
            height: root.listHeight
        }
    }

    // === CRT material, texture only — curvature off (warping a small
    // corner rectangle reads as a lens bulge, not "an old screen").
    // Aberration on — was silently disabled before along with curvature,
    // see Theme/Effects/CRTStack.qml. No flicker (a random white flash on
    // something meant to be skimmed fast reads as a bug, or worse, gets
    // mistaken for a new notification arriving). ===
    Effects.CRTStack {
        anchors.fill: parent
        sourceItem: mainContent
        strength: 0.25
        curvatureEnabled: false
        aberrationEnabled: true
        flickerEnabled: false
    }
}
