import QtQuick
import Quickshell
import Quickshell.Io
import "../../Theme"

// Path matches what your waybar config was already using — thermal-zone
// and hwmon-path are both commented out there, so it was already falling
// back to waybar's own default (thermal-zone 0), confirmed from the
// actual config rather than guessed.
//
// FileView over Process+cat here — no process-spawn overhead for reading
// one small pseudo-file every few seconds. text() is technically a
// method, not a property (per Quickshell's own docs), but it still fires
// textChanged() reactively, so binding to it directly works the same way
// a real property would.
//
// Sysfs value is in millidegrees Celsius, hence /1000. watchChanges is
// enabled defensively, but sysfs pseudo-files generally don't support
// real inotify watching the way normal files do — the Timer below, not
// the watch, is the actual reliable update mechanism.
Rectangle {
    id: root

    readonly property string rawText: tempFile.text()
    readonly property bool hasReading: rawText.length > 0 && !isNaN(parseInt(rawText))
    readonly property real temperatureC: hasReading ? parseInt(rawText) / 1000 : 0

    readonly property int criticalThreshold: 80 // matches the old config

    readonly property color textColor: (hasReading && temperatureC >= criticalThreshold)
        ? Colors.dangerAccent
        : Colors.textPrimary

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
        text: root.hasReading ? (Math.round(root.temperatureC) + "°C") : "—"
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

    FileView {
        id: tempFile
        path: "/sys/class/thermal/thermal_zone0/temp"
        watchChanges: true
        onFileChanged: reload()
    }

    Timer {
        interval: 4000 // matches the old config's own interval: 4
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: tempFile.reload()
    }

    // Confirmed from the actual config: on-click: "kitty -e btop" — same
    // action memory and cpu will use too, since btop already covers all
    // three at a glance rather than needing separate dedicated tools.
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: Quickshell.execDetached(["kitty", "-e", "btop"])
    }
}
