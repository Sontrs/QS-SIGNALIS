import QtQuick

// Very subtle, randomly-timed white flash — a full-screen brightness
// flicker rather than a shader effect, matching the original.
Rectangle {
    id: root
    color: "white"
    opacity: 0

    property int minPauseMs: 2000
    property int maxPauseMs: 5000

    SequentialAnimation on opacity {
        loops: Animation.Infinite
        PauseAnimation {
            duration: root.minPauseMs + Math.random() * (root.maxPauseMs - root.minPauseMs)
        }
        NumberAnimation { to: 0.03; duration: 50 }
        NumberAnimation { to: 0; duration: 50 }
        NumberAnimation { to: 0.02; duration: 30 }
        NumberAnimation { to: 0; duration: 30 }
    }
}
