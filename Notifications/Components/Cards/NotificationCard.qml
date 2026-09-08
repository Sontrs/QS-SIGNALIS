import QtQuick
import "../../../Components/Frames"
import "../../../Theme"


Item {
    id: root

    property string appName: ""
    property string summary: ""
    property string body: ""
    property string urgencyText: "NOMINAL"
    property color urgencyColor: Colors.nominalAccent

    implicitWidth: Metrics.notificationCardWidth
    implicitHeight: content.height + Metrics.notificationCardTopBarHeight + Metrics.sizeMedium * 2

    // A plain Item never auto-applies implicitWidth/implicitHeight to its
    // actual width/height the way Text or Image do. Without this, a
    // consumer that only anchors width (not height) ends up with a
    // 0-height, invisible card even though everything inside still runs.
    width: implicitWidth
    height: implicitHeight

    CutFrame {
        anchors.fill: parent
        strokeColor: Colors.redAccent
        fillColor: Colors.bgBase
    }

    // Thick top bar
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: Metrics.notificationCardTopBarHeight
        color: Colors.redAccent
    }

    Column {
        id: content
        anchors.top: parent.top
        anchors.topMargin: Metrics.notificationCardTopBarHeight + Metrics.sizeMedium
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Metrics.sizeMedium
        spacing: Metrics.sizeTiny

        Item {
            width: parent.width
            height: Math.max(appNameLabel.implicitHeight, urgencyLabel.implicitHeight)

            Text {
                id: appNameLabel
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: root.appName
                font.family: Fonts.currentFamily
                font.pixelSize: Fonts.small
                color: Colors.textPrimary
            }

            Text {
                id: urgencyLabel
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: root.urgencyText
                font.family: Fonts.currentFamily
                font.bold: true
                font.pixelSize: Fonts.body
                color: root.urgencyColor
            }
        }

        Text {
            width: parent.width
            visible: root.summary !== ""
            text: root.summary
            font.family: Fonts.currentFamily
            font.bold: true
            font.pixelSize: Fonts.small
            color: Colors.textPrimary
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            text: root.body
            wrapMode: Text.WordWrap
            maximumLineCount: 3
            elide: Text.ElideRight
            font.family: Fonts.currentFamily
            font.pixelSize: Fonts.small
            color: Colors.textPrimary
        }
    }
}
