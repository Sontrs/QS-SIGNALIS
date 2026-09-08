import QtQuick
import Quickshell
import Quickshell.Io
import "../../Theme"
import "../../Components/Popups" as Popups

// Format/interval confirmed from the actual config:
// "{max_frequency}GHz | {usage}%", interval: 1.
//
// Usage: standard /proc/stat delta technique — the file only reports
// cumulative jiffie counters since boot, not an instantaneous percentage,
// so this needs two samples and compares them. Handled reactively via
// onTextChanged rather than assuming reload() completes synchronously
// (Quickshell's own docs describe loads as backgrounded by default), so
// the delta math only runs once fresh content has actually arrived,
// regardless of how that timing actually works internally.
//
// Frequency: max scaling_cur_freq across all logical cores, not
// /proc/cpuinfo's "cpu MHz" field. That field is well-documented as
// unreliable on modern Intel CPUs specifically (confirmed via an htop bug
// report describing this exact symptom) — it reflects raw MSR counter
// sampling that can catch a core mid-idle-dip, not what the governor is
// actually targeting. scaling_cur_freq is the standard fix. This needs
// shell globbing across per-core files (cpu0, cpu1, ...), which
// Process/execDetached don't do without an explicit shell — hence the
// "sh -c" wrapper below rather than a plain argv list.
//
// Per-core tooltip: same delta technique as the aggregate line, just
// applied to each cpuN line in /proc/stat too — those immediately follow
// the aggregate "cpu " line, in core order, up until the first line that
// isn't a cpuN line (intr, ctxt, etc). Core count isn't hardcoded
// anywhere — the tooltip just repeats over however many showed up, so
// this doesn't need touching on a different machine with a different
// core count.
Rectangle {
    id: root

    property real usagePercent: 0
    property real maxFrequencyGHz: 0
    property var corePercentages: []

    property real prevIdle: 0
    property real prevTotal: 0
    property bool hasPrevSample: false

    property var prevCoreIdle: []
    property var prevCoreTotal: []
    property bool hasPrevCoreSample: false

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
        text: root.maxFrequencyGHz.toFixed(2) + "GHz | " + Math.round(root.usagePercent) + "%"
        color: Colors.textPrimary
        font.family: Fonts.currentFamily
        font.pixelSize: Fonts.body
    }

    function updateUsage(statText) {
        const lines = statText.split("\n");
        const firstLine = lines[0];
        // cpu  user nice system idle iowait irq softirq steal guest guest_nice
        const fields = firstLine.trim().split(/\s+/).slice(1).map(Number);
        const idle = fields[3] + (fields[4] || 0); // idle + iowait
        const total = fields.reduce((a, b) => a + b, 0);

        if (root.hasPrevSample) {
            const deltaIdle = idle - root.prevIdle;
            const deltaTotal = total - root.prevTotal;
            if (deltaTotal > 0)
                root.usagePercent = 100 * (1 - deltaIdle / deltaTotal);
        }
        root.prevIdle = idle;
        root.prevTotal = total;
        root.hasPrevSample = true;

        // cpuN lines immediately follow the aggregate line, in order,
        // until the first line that isn't one (intr, ctxt, ...).
        const coreLines = [];
        for (let i = 1; i < lines.length; i++) {
            if (/^cpu\d+/.test(lines[i]))
                coreLines.push(lines[i]);
            else
                break;
        }

        const newPercentages = [];
        const newPrevIdle = [];
        const newPrevTotal = [];
        for (let i = 0; i < coreLines.length; i++) {
            const coreFields = coreLines[i].trim().split(/\s+/).slice(1).map(Number);
            const coreIdle = coreFields[3] + (coreFields[4] || 0);
            const coreTotal = coreFields.reduce((a, b) => a + b, 0);

            let percent = 0;
            if (root.hasPrevCoreSample && root.prevCoreTotal.length > i) {
                const deltaIdle = coreIdle - root.prevCoreIdle[i];
                const deltaTotal = coreTotal - root.prevCoreTotal[i];
                if (deltaTotal > 0)
                    percent = 100 * (1 - deltaIdle / deltaTotal);
            }
            newPercentages.push(percent);
            newPrevIdle.push(coreIdle);
            newPrevTotal.push(coreTotal);
        }

        root.corePercentages = newPercentages;
        root.prevCoreIdle = newPrevIdle;
        root.prevCoreTotal = newPrevTotal;
        root.hasPrevCoreSample = true;
    }

    FileView {
        id: statFile
        path: "/proc/stat"
        onTextChanged: root.updateUsage(text())
    }

    Process {
        id: freqProcess
        command: ["sh", "-c", "cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                // One frequency in KHz per line, one line per logical
                // core.
                let maxKHz = 0;
                for (const line of this.text.trim().split("\n")) {
                    const khz = parseInt(line);
                    if (!isNaN(khz))
                        maxKHz = Math.max(maxKHz, khz);
                }
                root.maxFrequencyGHz = maxKHz / 1000000;
            }
        }
    }

    Timer {
        interval: 1000 // matches the old config's own interval: 1
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            statFile.reload();
            freqProcess.running = true;
        }
    }

    // Confirmed from the actual config: on-click: "kitty -e btop" — same
    // as temperature and memory.
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: Quickshell.execDetached(["kitty", "-e", "btop"])
    }

    Popups.Tooltip {
        hoverTarget: root
        hovered: mouseArea.containsMouse

        Column {
            spacing: Metrics.sizeTiny

            Text {
                text: "Total: " + Math.round(root.usagePercent) + "%"
                color: Colors.textPrimary
                font.family: Fonts.currentFamily
                font.pixelSize: Fonts.small
            }
            Repeater {
                model: root.corePercentages.length

                Text {
                    required property int index
                    text: "Core" + index + ": " + Math.round(root.corePercentages[index]) + "%"
                    color: Colors.textPrimary
                    font.family: Fonts.currentFamily
                    font.pixelSize: Fonts.small
                }
            }
        }
    }
}
