import QtQuick
import "../../Components/Frames" as Frames
import "../../Theme"

Item {
    id: root
    width: parent.width
    height: Metrics.searchBarHeight

    signal moveUp
    signal moveDown
    signal activateCurrent
    signal escapePressed

    property alias text: inputField.text
    property alias input: inputField

    Frames.CutFrame {
        anchors.fill: parent
        cutBottomRight: true
        strokeColor: Colors.redAccent
        fillColor: Colors.bgBase
    }

    TextInput {
        id: inputField
        anchors.fill: parent
        anchors.leftMargin: Metrics.sizeXLarge + Metrics.sizeSmall
        anchors.topMargin: Metrics.sizeLarge
        color: Colors.textPrimary
        font.family: Fonts.currentFamily
        font.pointSize: Fonts.body
        focus: true
        enabled: true

        Keys.onPressed: event => {
            switch (event.key) {
            case Qt.Key_Escape:
                root.escapePressed();
                event.accepted = true;
                break;
            case Qt.Key_Up:
                root.moveUp();
                event.accepted = true;
                break;
            case Qt.Key_Down:
                root.moveDown();
                event.accepted = true;
                break;
            case Qt.Key_Return:
            case Qt.Key_Enter:
                root.activateCurrent();
                event.accepted = true;
                break;
            }
        }
    }

    // Left accent bar
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: Metrics.sizeXLarge - 4
        color: Colors.redAccent
    }
}
