import QtQuick
import QtQuick.Shapes
import "../../Theme"

Item {
    id: root

    anchors.fill: parent

    // === Appearance ===
    property color strokeColor: Colors.grayAccent
    property int strokeWidth: Metrics.borderThin

    // === Geometry ===
    property real scaleFactor: 0.4
    property real verticalOffset: Metrics.sizeSmall

    Shape {
        anchors.fill: parent

        layer.enabled: true
        layer.smooth: true

        ShapePath {
            strokeWidth: root.strokeWidth
            strokeColor: root.strokeColor
            fillColor: "transparent"

            PathMove {
                x: root.width * (0.5 - root.scaleFactor / 2 * 0.7)
                y: root.height * (0.5 - root.scaleFactor / 2)
                   + root.verticalOffset
            }

            PathLine {
                x: root.width * (0.5 + root.scaleFactor / 2 * 0.7)
                y: root.height * (0.5 + root.scaleFactor / 2)
                   + root.verticalOffset
            }

            PathMove {
                x: root.width * (0.5 - root.scaleFactor / 2 * 0.7)
                y: root.height * (0.5 + root.scaleFactor / 2)
                   + root.verticalOffset
            }

            PathLine {
                x: root.width * (0.5 + root.scaleFactor / 2 * 0.7)
                y: root.height * (0.5 - root.scaleFactor / 2)
                   + root.verticalOffset
            }
        }
    }
}
