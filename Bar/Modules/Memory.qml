import QtQuick
import Quickshell
import Quickshell.Io
import "../../Theme"

// /proc/meminfo values are already in KiB despite the "kB" label (a
// long-standing, well-known Linux kernel naming quirk) — MemTotal and
// MemAvailable divided by 1024*1024 gives GiB directly, the same math
// `free -h`/htop use. Waybar's own internal unit-conversion table
// (calc_divisor in memory/common.cpp) looked like it uses a slightly
// different, more approximate factor for GiB specifically rather than a
// clean 1024*1024 — numbers here should be very close to what waybar
// showed, but I can't promise bit-for-bit identical, worth knowing rather
// than claiming exact parity I didn't verify.
//
// memfree uses MemAvailable when present, which is universal on any
// kernel from the last decade-plus — waybar's old Buffers+Cached
// approximation for pre-3.4 kernels isn't a real concern here.
//
// FileView over Process+cat, same reasoning as Temperature: no
// process-spawn overhead for reading one small pseudo-file periodically.
Rectangle {
    id: root

    readonly property var parsedMeminfo: {
        const text = meminfoFile.text();
        let memTotalKb = 0;
        let memAvailableKb = 0;
        for (const line of text.split("\n")) {
            const match = line.match(/^(\w+):\s+(\d+)/);
            if (!match)
                continue;
            if (match[1] === "MemTotal")
                memTotalKb = parseInt(match[2]);
            else if (match[1] === "MemAvailable")
                memAvailableKb = parseInt(match[2]);
        }
        return { total: memTotalKb, available: memAvailableKb };
    }

    readonly property real totalGiB: parsedMeminfo.total / (1024 * 1024)
    readonly property real usedGiB: (parsedMeminfo.total - parsedMeminfo.available) / (1024 * 1024)

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
        text: root.usedGiB.toFixed(2) + " / " + root.totalGiB.toFixed(0) + " GB"
        color: Colors.textPrimary
        font.family: Fonts.currentFamily
        font.pixelSize: Fonts.body
    }

    FileView {
        id: meminfoFile
        path: "/proc/meminfo"
        watchChanges: true
        onFileChanged: reload()
    }

    Timer {
        interval: 30000 // matches the old config's own interval: 30
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: meminfoFile.reload()
    }

    // Confirmed from the actual config: on-click: "kitty -e btop" — same
    // as temperature and cpu.
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: Quickshell.execDetached(["kitty", "-e", "btop"])
    }
}
