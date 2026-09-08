import QtQuick
import Quickshell.Services.UPower
import "../../Theme"
import "../../Components/Popups" as Popups

// UPower is DBus-based and push-driven. Properties update via signals
// as they change, not polling — unlike most modules here, no Timer or
// Process needed at all.
//
// Thresholds (critical <= 15, warning <= 30) match the actual config's
// own "states" block, reusing the same caution/danger tokens Storage
// already uses for severity rather than inventing new ones.
//
//
// Tooltip: timeToEmpty/timeToFull, both in seconds. Each reads 0
// whenever it doesn't apply (timeToEmpty is 0 while charging, timeToFull is 0 while
// discharging)
Rectangle {
    id: root

    readonly property var device: UPower.displayDevice
    readonly property real percent: device.percentage * 100
    readonly property bool charging: device.state === UPowerDeviceState.Charging

    readonly property color textColor: {
        if (percent <= 15)
            return Colors.dangerAccent;
        if (percent <= 30)
            return Colors.cautionAccent;
        return Colors.textPrimary;
    }

    width: label.implicitWidth + Metrics.sizeMedium * 2
    height: 24
    color: "transparent"

    Text {
        id: label
        anchors.centerIn: parent
        text: root.device.ready ? ("B" + Math.round(root.percent) + "%" + (root.charging ? "+" : "")) : "—"
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

    // No click action here, so no hover-tint background either (that's
    // reserved for actually-clickable modules elsewhere) — this
    // MouseArea exists purely to feed the tooltip's hover state.
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
    }

    Popups.Tooltip {
        hoverTarget: root
        hovered: mouseArea.containsMouse

        Column {
            spacing: Metrics.sizeTiny
            visible: root.device.ready && (root.device.timeToEmpty > 0 || root.device.timeToFull > 0)

            Text {
                visible: root.device.timeToEmpty > 0
                text: "Time to empty: " + root.formatSeconds(root.device.timeToEmpty)
                color: Colors.textPrimary
                font.family: Fonts.currentFamily
                font.pixelSize: Fonts.small
            }
            Text {
                visible: root.device.timeToFull > 0
                text: "Time to full: " + root.formatSeconds(root.device.timeToFull)
                color: Colors.textPrimary
                font.family: Fonts.currentFamily
                font.pixelSize: Fonts.small
            }
        }

        // Fallback when UPower doesn't have a time estimate yet (common
        // right after boot, or on a desktop with no real battery) — an
        // empty tooltip would just look broken.
        Text {
            visible: !root.device.ready || (root.device.timeToEmpty <= 0 && root.device.timeToFull <= 0)
            text: "No estimate available"
            color: Colors.textPrimary
            font.family: Fonts.currentFamily
            font.pixelSize: Fonts.small
        }
    }

    function formatSeconds(seconds) {
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        return hours + "h " + minutes + "m";
    }
}
