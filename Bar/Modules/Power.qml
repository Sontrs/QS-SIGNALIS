import QtQuick
import "../../Theme"

// No local state to hold, unlike IdleInhibitorButton's genuinely-local
// "active" toggle — the real open/closed state (root.logoutOpen) already
// lives in shell.qml, and WLogout's own full-screen falling-buttons
// entrance is plenty of feedback that the menu opened. Just fires a
// signal upward on click and leaves it at that; Bar.qml re-emits it,
// shell.qml flips the actual boolean. Same shape as AppLauncher's and
// WLogout's own closeRequested — a module announces intent, whoever owns
// the real state decides what to do with it.
Rectangle {
    id: root

    signal powerRequested()

    width: 24
    height: 24
    color: mouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : "transparent"

    Behavior on color {
        ColorAnimation {
            duration: Metrics.animFast
            easing.type: Easing.OutQuad
        }
    }

    Text {
        anchors.centerIn: parent
        text: "P"
        color: Colors.textPrimary
        font.family: Fonts.currentFamily
        font.pixelSize: Fonts.small
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.powerRequested()
    }
}
