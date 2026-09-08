import QtQuick
import "../../Theme"

// Four "+" corner marks, inset by `margin` from whatever bounds the caller
// gives it (typically via anchors.fill)
Item {
    id: root

    // === Styling ===
    property color crossColor: Colors.whiteAccent

    property int margin: Metrics.sizeMedium - 2
    property int pixelSize: Fonts.body

    Repeater {
        model: [
            { x: 0, y: 0 },
            { x: 1, y: 0 },
            { x: 0, y: 1 },
            { x: 1, y: 1 }
        ]

        delegate: Text {
            text: "+"

            color: root.crossColor

            font.family: Fonts.currentFamily
            font.pixelSize: root.pixelSize

            anchors {
                left: modelData.x === 0 ? parent.left : undefined
                right: modelData.x === 1 ? parent.right : undefined

                top: modelData.y === 0 ? parent.top : undefined
                bottom: modelData.y === 1 ? parent.bottom : undefined

                leftMargin: root.margin
                rightMargin: root.margin

                topMargin: root.margin
                bottomMargin: root.margin
            }
        }
    }
}
