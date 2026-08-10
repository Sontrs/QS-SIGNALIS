import QtQuick
import "../../../Components/Frames"
import "../../../Theme"

Item {
    id: root

    implicitWidth: Metrics.appCardWidth
    implicitHeight: Metrics.appCardHeight

    // === Data ===
    property bool isSelected: false
    property string title: ""
    property string iconSource: ""

    readonly property bool hasIcon: root.iconSource !== ""

    // Old code used dark text in both states, since it reads fine against
    // both the grey (unselected) and red (selected) fills. No need to flip.
    readonly property color textColor: Colors.bgBase

    signal focused
    signal activated

    CutFrame {
        id: appFrame
        anchors.fill: parent
        cutBottomLeft: true
        cutTopRight: true
        isSelected: root.isSelected
        // Old code filled unselected rows with medium grey, not the dark
        // panel background — CutFrame's own default (bgBase) is meant for
        // outer frames, not per-row cards, so it has to be overridden here.
        strokeColor: Colors.grayAccent
        fillColor: Colors.grayAccent
    }

    Row {
        anchors.centerIn: parent
        spacing: Metrics.sizeLarge

        Image {
            id: appIcon
            width: Metrics.iconMedium
            height: Metrics.iconMedium
            anchors.verticalCenter: parent.verticalCenter
            source: root.iconSource
            fillMode: Image.PreserveAspectFit
            smooth: true
            visible: root.hasIcon
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.title
            font.family: Fonts.currentFamily
            font.pixelSize: Fonts.title
            color: root.textColor
        }
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: root.focused()
        onDoubleTapped: root.activated()
    }
}
