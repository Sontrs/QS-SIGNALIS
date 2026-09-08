import QtQuick
import "../../Theme"


Item {
    id: root
    anchors.fill: parent

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
