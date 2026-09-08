import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../Theme"
import "../Frames" as Frames

// Shared hover-tooltip shell — one instance per module that wants one,
// not a single instance juggled between five different hover sources.
// PopupWindows cost basically nothing while hidden (the same reasoning
// Bar/NotificationPopup already lean on to justify staying always-
// resident instead of Loader/LazyLoader), so per-module ownership is
// simpler to reason about than threading one shared popup's content and
// anchor identity through a hoveredModule property every time focus
// moves between modules.
//
// `hovered` is meant to bind straight to the host module's own
// `mouseArea.containsMouse` — the ~400ms show delay (standard desktop
// tooltip behavior, avoiding a flash on every simple mouse-pass over the
// bar) lives in here rather than being a Timer duplicated in five
// separate module files. Hiding has no delay — that would just make the
// tooltip feel laggy to dismiss.

// No fold/collapse animation yet — that's waiting on reference
// screenshots. Just a plain opacity fade in the meantime so appearing
// isn't jarring to look at while it's absent.

PopupWindow {
    id: root

    required property Item hoverTarget
    property bool hovered: false
    default property alias content: contentContainer.data

    implicitWidth: contentContainer.implicitWidth + Metrics.sizeMedium * 2
    implicitHeight: contentContainer.implicitHeight + Metrics.sizeMedium * 2
    color: "transparent"

    anchor.item: hoverTarget
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: Metrics.sizeTiny

    property bool wantShow: false

    Timer {
        id: showDelay
        interval: 400
        onTriggered: root.wantShow = true
    }

    onHoveredChanged: {
        if (hovered) {
            showDelay.restart();
        } else {
            showDelay.stop();
            root.wantShow = false;
        }
    }

    property real fadeOpacity: wantShow ? 1 : 0
    HyprlandWindow.opacity: root.fadeOpacity

    Behavior on fadeOpacity {
        NumberAnimation {
            duration: Metrics.animFast
            easing.type: Easing.OutQuad
        }
    }

    // Stays visible through the fade-out, not just the fade-in. Dropping
    // straight to invisible the instant wantShow goes false would cut the
    // animation off after one frame instead of letting it actually play.
    visible: wantShow || fadeOpacity > 0

    Frames.CutFrame {
        anchors.fill: parent
        strokeColor: Colors.redAccent
    }

    // notificationCardTopBarHeight, not borderThick — that value's for a
    // full-width screen-edge line (Bar's own bottom accent), which reads
    // fine that thin in that context. A boxed panel like this one needs
    // the "individual card, urgency-colored, no text" precedent instead,
    // or it just gets swallowed by CutFrame's own 2px border sitting
    // right underneath it.
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: Metrics.notificationCardTopBarHeight
        color: Colors.redAccent
    }

    Item {
        id: contentContainer
        anchors.fill: parent
        anchors.margins: Metrics.sizeMedium
        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height
    }
}
