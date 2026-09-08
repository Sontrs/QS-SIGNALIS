import QtQuick
import Quickshell
import Quickshell.Io
import "../../Theme"

// Via brightnessctl
Rectangle {
    id: root

    property int percent: 0

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
        text: root.percent + "%"
        color: Colors.textPrimary
        font.family: Fonts.currentFamily
        font.pixelSize: Fonts.body
    }

    Process {
        id: readProcess
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                // device,class,current,percent,max may include a
                // trailing "%" depending on version; parseInt stops at the
                // first non-digit either way, so no need to strip it.
                const fields = this.text.trim().split(",");
                if (fields.length >= 4)
                    root.percent = parseInt(fields[3]);
            }
        }
    }

    // brightnessctl has no built-in watch/event mode, so this polls
    // rather than reacting instantly — same interval-based approach
    // Quickshell's own tutorial uses for comparable exec-based stats.
    // Scrolling also triggers an immediate re-read, so the only real
    // latency this leaves is for changes made outside this button
    // entirely (a hardware Fn key, etc).
    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: readProcess.running = true
    }

    function adjust(delta) {
        const magnitude = Math.abs(delta);

        const arg = delta > 0 ? ("+" + magnitude + "%") : (magnitude + "%-");
        Quickshell.execDetached(["brightnessctl", "set", arg]);
        // Optimistic local update so the label doesn't wait for the next
        // poll, then a short delayed re-read to correct for clamping at
        // 0%/100% (brightnessctl itself enforces the clamp, this is just
        // the label catching up to the real value).
        root.percent = Math.max(0, Math.min(100, root.percent + delta));
        readDelay.restart();
    }

    Timer {
        id: readDelay
        interval: 150
        onTriggered: readProcess.running = true
    }


    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onWheel: event => root.adjust(event.angleDelta.y > 0 ? 5 : -5)
    }
}
