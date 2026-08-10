import QtQuick
import "../../Theme"

Item {
    id: root

    // === Direction ===
    enum Direction {
        Left,
        Right
    }

    property int direction: ArrowButton.Right

    // === State ===
    property bool active: false

    // === Styling ===
    property color activeColor: Colors.redAccent
    property color inactiveColor: Colors.darkerGrayAccent

    property int pixelSize: Metrics.arrowSize

    // === Layout ===
    property real leftPadding: 0
    property real rightPadding: 0

    readonly property color currentColor:
        active ? activeColor : inactiveColor

    Text {
        anchors.fill: parent

        text: root.direction === ArrowButton.Right
              ? "🞂"
              : "🞀"

        color: root.currentColor

        font.family: Fonts.currentFamily
        font.pixelSize: root.pixelSize

        leftPadding: root.leftPadding
        rightPadding: root.rightPadding

        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter

        // Behavior on color {
        //     ColorAnimation {
        //         duration: Metrics.animNormal
        //         easing.type: Easing.OutQuad
        //     }
        // }
    }
}
