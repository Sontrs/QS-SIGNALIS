import QtQuick
import Quickshell.Wayland
import "../../Theme"

// IdleInhibitor itself has no UI — it's a plain non-visual object that
// holds/releases the real wayland idle-inhibit-unstable-v1 lock based on
// `enabled`, given a `window` reference. This file supplies the clickable
// on/off button around it.
//
// `window` is passed in from outside (the bar's own PanelWindow) rather
// than looked up automatically — IdleInhibitor needs a real window
// reference to be honored by the compositor, and per Quickshell's docs a
// PanelWindow is exactly what compositors are expected to treat as
// "important" enough to respect.
Rectangle {
    id: root
    required property QtObject window

    property bool active: false

    width: 24
    height: 24
    // "Black when off" taken literally would mean matching the bar's own
    // background color exactly, making the button invisible with nothing
    // to click on — used the theme's darker gray token instead so there's
    // always a visible, clickable boundary regardless of state.
    color: {
        if (active)
            return Colors.redAccent;
        return mouseArea.containsMouse ? Colors.grayAccent : Colors.darkerGrayAccent;
    }

    Behavior on color {
        ColorAnimation {
            duration: Metrics.animFast
            easing.type: Easing.OutQuad
        }
    }

    IdleInhibitor {
        window: root.window
        enabled: root.active
    }

    Text {
        anchors.centerIn: parent
        text: "C"
        color: root.active ? Colors.bgBase : Colors.textPrimary
        font.family: Fonts.currentFamily
        font.pixelSize: Fonts.small
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.active = !root.active
    }
}
