import QtQuick
import "../../Theme"

// Edge-fade overlays so content scrolling behind the panel (AppList)
// fades out at the top/bottom instead of cutting off sharply.
//
// Each edge stacks several identical gradient rectangles rather than
// using one. This is intentional: overlapping semi-transparent layers
// compound their opacity, giving a darker/harder falloff at the
// partial-alpha stops than a single gradient layer can achieve alone.
Item {
    id: root
    anchors.fill: parent

    // Qt.alpha() isn't a real Qt Quick function — this was the same mistake
    // made (and fixed) in NotificationCard.qml. Qt.rgba() with the base
    // color's own r/g/b components is the correct way to get a specific
    // alpha.
    function fade(alpha) {
        return Qt.rgba(Colors.bgBase.r, Colors.bgBase.g, Colors.bgBase.b, alpha);
    }

    // top shadow
    Repeater {
        model: 4

        Rectangle {
            anchors.top: root.top
            anchors.left: root.left
            anchors.right: root.right
            anchors.margins: 2
            height: 190
            gradient: Gradient {
                GradientStop { position: 0.0; color: Colors.bgBase }
                GradientStop { position: 0.5; color: root.fade(0.67) }
                GradientStop { position: 0.75; color: root.fade(0.33) }
                GradientStop { position: 1.0; color: root.fade(0.0) }
            }
            z: 3
        }
    }

    // bottom shadow
    Repeater {
        model: 6

        Rectangle {
            anchors.bottom: root.bottom
            anchors.left: root.left
            anchors.right: root.right
            anchors.margins: 2
            height: 150
            gradient: Gradient {
                GradientStop { position: 0.0; color: root.fade(0.0) }
                GradientStop { position: 0.5; color: root.fade(0.33) }
                GradientStop { position: 0.75; color: root.fade(0.67) }
                GradientStop { position: 1.0; color: Colors.bgBase }
            }
            z: 3
        }
    }
}
