import QtQuick
import "../../../Components/Frames"
import "../../../Components/Decorations"
import "../../../Theme"

Item {
    id: root

    implicitWidth: Metrics.favoriteCardWidth
    implicitHeight: Metrics.favoriteCardHeight

    // === Data ===
    property string title: ""
    property string iconSource: ""
    property int slotNumber: 0
    property bool isCurrent: false

    readonly property bool hasIcon: root.iconSource !== ""
    readonly property bool isEmpty: root.title === ""

    signal activated

    // === Frame ===
    CutFrame {
        id: cardFrame
        anchors.fill: parent
        cutBottomRight: true
        strokeColor: root.isEmpty ? Colors.grayAccent : Colors.redAccent
        fillColor: Colors.bgBase
    }

    // === Icon ===
    Image {
        id: appIcon
        anchors.centerIn: parent
        anchors.verticalCenterOffset: Metrics.sizeSmall - 3
        width: Metrics.iconLarge
        height: Metrics.iconLarge
        source: root.iconSource
        fillMode: Image.PreserveAspectFit
        smooth: true
        visible: root.hasIcon
    }

    // Shown when the slot has nothing assigned, or the icon failed to resolve
    EmptySlotX {
        visible: root.isEmpty || !root.hasIcon
        strokeColor: root.isEmpty ? Colors.grayAccent : Colors.redAccent
    }

    // === Top label bar ===
    Rectangle {
        width: parent.width
        height: Metrics.sizeXLarge - 4
        color: root.isEmpty ? Colors.grayAccent : Colors.redAccent

        Text {
            text: root.isEmpty ? "EMPTY SLOT" : root.title
            anchors.left: parent.left
            anchors.leftMargin: Metrics.textInsetSmall - 1
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Metrics.textInsetSmall - 1
            font.family: Fonts.currentFamily
            font.pixelSize: Fonts.small + 3
            color: Colors.bgBase
        }
    }

    // === Slot number ===
    Text {
        text: root.slotNumber
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: Metrics.textInsetLarge - 4
        anchors.bottomMargin: Metrics.textInsetSmall
        font.family: Fonts.currentFamily
        font.pixelSize: Fonts.small + 2
        color: root.isEmpty ? Colors.grayAccent : Colors.whiteAccent
    }

    // === Current-slot indicator ===
    // A thin highlight so the carousel's centered item reads clearly
    // even before FavoritesCarousel adds its own indicator dots.
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.color: Colors.whiteAccent
        border.width: root.isCurrent ? Metrics.borderThin : 0
        visible: root.isCurrent

        Behavior on border.width {
            NumberAnimation {
                duration: Metrics.animFast
                easing.type: Easing.OutQuad
            }
        }
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        enabled: !root.isEmpty
        onTapped: root.activated()
    }
}
