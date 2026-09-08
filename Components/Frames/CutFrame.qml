import QtQuick
import QtQuick.Shapes
import "../../Theme"

Item {
    id: root

    // === Appearance ===
    property color strokeColor: Colors.grayAccent
    property color fillColor: Colors.bgBase

    property int strokeWidth: Metrics.borderNormal
    property int cutSize: Metrics.cutSizeMedium

    // === Corner control ===
    property bool cutTopLeft: false
    property bool cutTopRight: false
    property bool cutBottomRight: false
    property bool cutBottomLeft: false

    // === Optional selection state ===
    property bool isSelected: false

    // Optional selected colors
    property color selectedStrokeColor: Colors.redAccent
    property color selectedFillColor: Colors.redAccent

    readonly property bool hasAnyCut: root.cutTopLeft || root.cutTopRight
                                       || root.cutBottomRight || root.cutBottomLeft

    readonly property color activeStrokeColor: root.isSelected
                                                 ? root.selectedStrokeColor
                                                 : root.strokeColor
    readonly property color activeFillColor: root.isSelected
                                              ? root.selectedFillColor
                                              : root.fillColor

    // === Plain rectangle path (no cuts) ===
    Rectangle {
        anchors.fill: parent
        visible: !root.hasAnyCut
        color: root.activeFillColor
        border.width: root.strokeWidth
        border.color: root.activeStrokeColor

        Behavior on color {
            ColorAnimation {
                duration: Metrics.animNormal
                easing.type: Easing.OutQuad
            }
        }

        Behavior on border.color {
            ColorAnimation {
                duration: Metrics.animNormal
                easing.type: Easing.OutQuad
            }
        }
    }

    // === Cut-corner path (Shape) ===
    Shape {
        id: cutShape
        anchors.fill: parent
        visible: root.hasAnyCut

        // Builds the outline as an SVG path string, only emitting a diagonal
        // segment at corners that are actually cut. A fixed list of PathLine
        // elements always included a "corner" line even when going straight
        // through (a zero-length segment drawn on top of the point the edge
        // line had already reached), which QtQuick.Shapes can mishandle at
        // render time.
        function buildPath() {
            const w = root.width;
            const h = root.height;
            const c = root.cutSize;

            const tl = root.cutTopLeft;
            const tr = root.cutTopRight;
            const br = root.cutBottomRight;
            const bl = root.cutBottomLeft;

            const startX = tl ? c : 0;

            let d = `M ${startX} 0 `;

            d += `L ${tr ? w - c : w} 0 `;
            if (tr)
                d += `L ${w} ${c} `;

            d += `L ${w} ${br ? h - c : h} `;
            if (br)
                d += `L ${w - c} ${h} `;

            d += `L ${bl ? c : 0} ${h} `;
            if (bl)
                d += `L 0 ${h - c} `;

            d += `L 0 ${tl ? c : 0} `;
            if (tl)
                d += `L ${c} 0`;

            return d;
        }

        ShapePath {
            strokeWidth: root.strokeWidth
            strokeColor: root.activeStrokeColor
            fillColor: root.activeFillColor

            Behavior on fillColor {
                ColorAnimation {
                    duration: Metrics.animNormal
                    easing.type: Easing.OutQuad
                }
            }

            Behavior on strokeColor {
                ColorAnimation {
                    duration: Metrics.animNormal
                    easing.type: Easing.OutQuad
                }
            }

            PathSvg {
                path: cutShape.buildPath()
            }
        }
    }
}
