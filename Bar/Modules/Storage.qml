import QtQuick
import Quickshell
import Quickshell.Io
import "../../Theme"
import "../../Components/Popups" as Popups

// Ported directly from the old waybar storage.sh script's own logic (same
// `df -h -P -l /` call, same field layout, same warning/critical
// thresholds, same 60s interval — confirmed against the actual config,
// not guessed) rather than shelling out to a separate awk script — parsed
// here in JS instead, consistent with how Backlight already parses its
// own process output directly.
//
// Severity coloring reuses the same nominal/caution/danger urgency tokens
// NotificationPopup already established, rather than inventing a new
// warning color — this is exactly the kind of severity signal those
// tokens exist for.
//
// Left-click opens baobab, right-click toggles available-space/percentage
// display — both straight from the old config's on-click/format-alt-click
// behavior.
//
// Tooltip shows the remaining fields the old script's own output already
// had (filesystem/size/used/mounted on) — nothing new to gather, just
// wasn't being kept before.
Rectangle {
    id: root

    property string filesystemText: "—"
    property string sizeText: "—"
    property string usedText: "—"
    property string availableText: "—"
    property string mountedOnText: "—"
    property int usedPercent: 0
    property bool showPercentage: false

    readonly property int warningThreshold: 20  // % remaining
    readonly property int criticalThreshold: 10 // % remaining
    readonly property int remainingPercent: 100 - usedPercent

    readonly property color textColor: {
        if (remainingPercent < criticalThreshold)
            return Colors.dangerAccent;
        if (remainingPercent < warningThreshold)
            return Colors.cautionAccent;
        return Colors.textPrimary;
    }

    width: label.implicitWidth + Metrics.sizeMedium * 2
    height: 24
    color: mouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : "transparent"

    Behavior on color {
        ColorAnimation {
            duration: Metrics.animFast
            easing.type: Easing.OutQuad
        }
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.showPercentage ? (root.usedPercent + "%") : root.availableText
        color: root.textColor
        font.family: Fonts.currentFamily
        font.pixelSize: Fonts.body

        Behavior on color {
            ColorAnimation {
                duration: Metrics.animFast
                easing.type: Easing.OutQuad
            }
        }
    }

    Process {
        id: dfProcess
        command: ["df", "-h", "-P", "-l", "/"]
        stdout: StdioCollector {
            onStreamFinished: {
                // Line 0 is the header (Filesystem/Size/Used/Avail/Use%/
                // Mounted on), the actual data is line 1.
                const lines = this.text.trim().split("\n");
                if (lines.length < 2)
                    return;
                const fields = lines[1].trim().split(/\s+/);
                if (fields.length < 5)
                    return;
                // fields: [device, size, used, avail, use%, mountpoint]
                root.filesystemText = fields[0];
                root.sizeText = fields[1];
                root.usedText = fields[2];
                root.availableText = fields[3];
                root.usedPercent = parseInt(fields[4]);
                root.mountedOnText = fields[5];
            }
        }
    }

    Timer {
        interval: 60000 // matches the old config's own interval: 60
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: dfProcess.running = true
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton)
                Quickshell.execDetached(["baobab"]);
            else
                root.showPercentage = !root.showPercentage;
        }
    }

    Popups.Tooltip {
        hoverTarget: root
        hovered: mouseArea.containsMouse

        Column {
            spacing: Metrics.sizeTiny

            Text {
                text: "Filesystem: " + root.filesystemText
                color: Colors.textPrimary
                font.family: Fonts.currentFamily
                font.pixelSize: Fonts.small
            }
            Text {
                text: "Size: " + root.sizeText
                color: Colors.textPrimary
                font.family: Fonts.currentFamily
                font.pixelSize: Fonts.small
            }
            Text {
                text: "Used: " + root.usedText
                color: Colors.textPrimary
                font.family: Fonts.currentFamily
                font.pixelSize: Fonts.small
            }
            Text {
                text: "Avail: " + root.availableText
                color: Colors.textPrimary
                font.family: Fonts.currentFamily
                font.pixelSize: Fonts.small
            }
            Text {
                text: "Use%: " + root.usedPercent + "%"
                color: Colors.textPrimary
                font.family: Fonts.currentFamily
                font.pixelSize: Fonts.small
            }
            Text {
                text: "Mounted on: " + root.mountedOnText
                color: Colors.textPrimary
                font.family: Fonts.currentFamily
                font.pixelSize: Fonts.small
            }
        }
    }
}
