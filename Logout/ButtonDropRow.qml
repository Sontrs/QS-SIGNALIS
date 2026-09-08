import QtQuick
import QtQuick.Layouts

// Bespoke entrance animation for the Logout menu's button row.
Item {
    id: root

    property var buttons: []          // list of {label, text, keybind, exec}
    property color buttonColor: "#FF2A2A"
    property color buttonHoverColor: "#FFFFFF"
    property color impactColor: "#FF2A2A"  // shared starting tint, all columns

    property int fallDuration: 500
    property int buttonHeight: 32
    property real startHeightPx: 3
    property int ghostCount: 8

    property real dropStartY: root.height * 0.1
    readonly property real dropEndY: root.height - root.buttonHeight

    signal settled
    signal activated(int index)

    property real progress: 0

    NumberAnimation on progress {
        from: 0
        to: 1
        duration: root.fallDuration
        easing.type: Easing.OutQuad
        running: true
        onStopped: root.settled()
    }

    function lerpColor(a, b, t) {
        return Qt.rgba(
            a.r + (b.r - a.r) * t,
            a.g + (b.g - a.g) * t,
            a.b + (b.b - a.b) * t,
            a.a + (b.a - a.a) * t
        );
    }

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: 50

        Repeater {
            model: root.buttons

            delegate: Item {
                id: col
                required property var modelData
                required property int index
                Layout.fillWidth: true
                Layout.fillHeight: true

                readonly property color restColor: root.buttonColor
                readonly property color finalColor: ma.containsMouse ? root.buttonHoverColor : col.restColor

                readonly property real leadY: root.dropStartY + (root.dropEndY - root.dropStartY) * root.progress
                readonly property real leadHeight: root.startHeightPx + (root.buttonHeight - root.startHeightPx) * root.progress
                readonly property color leadColor: root.lerpColor(root.impactColor, col.restColor, root.progress)

                // Rolling buffer of past (y, height, color) samples for this
                // column's ghost trail. Reassigned (not mutated) each tick
                // so the Repeater below picks up the change.
                property var ghostBuffer: []

                Connections {
                    target: root
                    function onSettled() {
                        // The sampling Timer below already stops once
                        // progress reaches 1, but never clears what it had
                        // last collected — without this, the trail stays
                        // baked into the final button forever.
                        col.ghostBuffer = [];
                    }
                }

                Timer {
                    interval: Math.max(20, root.fallDuration / root.ghostCount)
                    running: root.progress < 1
                    repeat: true
                    onTriggered: {
                        const next = col.ghostBuffer.concat([{
                            y: col.leadY,
                            height: col.leadHeight,
                            color: col.leadColor
                        }]);
                        while (next.length > root.ghostCount)
                            next.shift();
                        col.ghostBuffer = next;
                    }
                }

                // === Ghost trail (oldest to newest, so newest paints on top) ===
                Repeater {
                    model: col.ghostBuffer

                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        width: col.width
                        y: modelData.y
                        height: modelData.height
                        color: modelData.color
                        // Older ghosts (lower index, since buffer is oldest-first)
                        // fade out more.
                        opacity: 0.15 + (0.55 * (index / Math.max(1, col.ghostBuffer.length - 1)))
                    }
                }

                // === Leading edge / final button ===
                Rectangle {
                    id: btnRect
                    width: col.width
                    y: col.leadY
                    height: col.leadHeight
                    color: root.progress < 1 ? col.leadColor : col.finalColor
                    border.color: root.buttonColor
                    border.width: (root.progress >= 1 && !ma.containsMouse) ? 1 : 0
                    radius: 1

                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: root.progress >= 1
                        onClicked: root.activated(col.index)
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: root.progress >= 1
                        text: col.modelData.text
                        font.family: "Visitor TT1 BRK"
                        font.letterSpacing: 13
                        font.pointSize: 20
                        color: "black"
                    }
                }
            }
        }
    }
}
