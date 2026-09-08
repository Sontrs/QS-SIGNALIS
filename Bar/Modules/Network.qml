import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import "../../Theme"
import "../../Components/Popups" as Popups

// Networking.devices lists every network device with no single "default
// device" convenience property the way Pipewire/UPower have — filters by
// DeviceType manually to find the wifi/wired device, then checks which
// network on it is actually connected.
//
// wifiDevice.scannerEnabled is explicitly turned on below — the docs
// describe it as what "populates the device with an active list of
// available wifi networks," which reads like the network list (and
// anything on it, including signal strength) may just sit as a stale
// snapshot without it. This is the best-reasoned explanation I have for
// live numbers being persistently ~20 points off waybar's and not
// tracking the same trend, but I can't fully confirm it without seeing
// it run — worth watching closely rather than trusting outright.
//
// signalStrength is a 0-1 fraction, not already 0-100 — same lesson as
// battery/volume, applied up front here instead of after a live bug this
// time.
//
// No PwObjectTracker-style binding step needed — nothing in Networking's
// docs (Network, NetworkDevice, WifiDevice, WifiNetwork) mentioned
// properties being invalid until explicitly bound the way Pipewire's did.
//
// IP address isn't exposed anywhere in this API — checked NetworkDevice,
// WifiDevice, and WiredDevice's properties, none of them have it — so the
// wired case can't fully replicate the old "{ifname}: {ipaddr}/{cidr}"
// format, and falls back to interface name + connected state instead.
// Left-click still opens nm-connection-editor, confirmed from the actual
// config.
//
// Tooltip needs four things Quickshell's own Networking API doesn't
// expose at all — frequency, raw signal dBm (signalStrength is only ever
// a 0-1 fraction), IP address, and bandwidth — so all four fall back to
// shell commands, same precedent CPU's own frequency reading already
// set for gaps in Quickshell's native data. `iw dev <iface> link` gives
// both frequency and dBm in one call for wifi (empty output on a wired
// link, which just leaves those two tooltip lines hidden); `ip -4 addr
// show dev <iface>` gives the IP for either connection type; bandwidth
// is /sys/class/net/<iface>/statistics/{rx,tx}_bytes delta'd between
// Timer ticks, the same technique CPU's own usage percent already uses
// against /proc/stat, just applied to a different sysfs source. `iw`
// isn't guaranteed installed on every distro the way `ip` is (that's
// iproute2, about as core as it gets) — worth checking if the wifi lines
// come up blank.
Rectangle {
    id: root

    readonly property var wifiDevice: {
        for (const device of Networking.devices.values) {
            if (device.type === DeviceType.Wifi)
                return device;
        }
        return null;
    }

    // Fires every time wifiDevice changes identity (null -> device on
    // startup, or if it's ever replaced) rather than being set once, so
    // scanning stays enabled even if the device object gets recreated.
    onWifiDeviceChanged: {
        if (wifiDevice)
            wifiDevice.scannerEnabled = true;
    }

    readonly property var wiredDevice: {
        for (const device of Networking.devices.values) {
            if (device.type === DeviceType.Wired)
                return device;
        }
        return null;
    }

    readonly property var connectedWifiNetwork: {
        if (!wifiDevice)
            return null;
        for (const network of wifiDevice.networks.values) {
            if (network.connected)
                return network;
        }
        return null;
    }

    readonly property string displayText: {
        if (connectedWifiNetwork)
            return connectedWifiNetwork.name + " (" + Math.round(connectedWifiNetwork.signalStrength * 100) + "%)";
        if (wiredDevice && wiredDevice.connected)
            return wiredDevice.name; // interface name only — no IP available, see comment above
        return "Disconnected";
    }

    readonly property string activeInterfaceName: {
        if (connectedWifiNetwork && wifiDevice)
            return wifiDevice.name;
        if (wiredDevice && wiredDevice.connected)
            return wiredDevice.name;
        return "";
    }

    property real frequencyMHz: 0
    property real signalDbm: 0
    property string ipAddress: "—"
    property real uploadBitsPerSec: 0
    property real downloadBitsPerSec: 0

    property real prevRxBytes: -1
    property real prevTxBytes: -1

    function formatBits(bitsPerSec) {
        if (bitsPerSec >= 1000000)
            return (bitsPerSec / 1000000).toFixed(1) + " Mb/s";
        if (bitsPerSec >= 1000)
            return (bitsPerSec / 1000).toFixed(1) + " Kb/s";
        return Math.round(bitsPerSec) + " b/s";
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
        text: root.displayText
        color: Colors.textPrimary
        font.family: Fonts.currentFamily
        font.pixelSize: Fonts.body
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: Quickshell.execDetached(["nm-connection-editor"])
    }

    // Positional $1 rather than string-interpolating the interface name
    // into the command — avoids building a shell string out of a value
    // that (in principle) came from a network-provided name.
    Process {
        id: statsProcess
        command: ["sh", "-c", "iw dev \"$1\" link 2>/dev/null; echo ---IP---; ip -4 addr show dev \"$1\" 2>/dev/null; echo ---BYTES---; cat /sys/class/net/\"$1\"/statistics/rx_bytes /sys/class/net/\"$1\"/statistics/tx_bytes 2>/dev/null", "sh", root.activeInterfaceName]
        stdout: StdioCollector {
            onStreamFinished: {
                const sections = this.text.split(/---IP---|---BYTES---/);
                const iwSection = sections[0] || "";
                const ipSection = sections[1] || "";
                const bytesSection = sections[2] || "";

                const freqMatch = iwSection.match(/freq:\s*(\d+)/);
                root.frequencyMHz = freqMatch ? parseInt(freqMatch[1]) : 0;

                const signalMatch = iwSection.match(/signal:\s*(-?\d+)\s*dBm/);
                root.signalDbm = signalMatch ? parseInt(signalMatch[1]) : 0;

                const ipMatch = ipSection.match(/inet (\d+\.\d+\.\d+\.\d+)/);
                root.ipAddress = ipMatch ? ipMatch[1] : "—";

                const byteValues = bytesSection.trim().split("\n").map(Number).filter(n => !isNaN(n));
                if (byteValues.length >= 2) {
                    const rxBytes = byteValues[0];
                    const txBytes = byteValues[1];
                    if (root.prevRxBytes >= 0) {
                        const elapsedSec = statsTimer.interval / 1000;
                        root.downloadBitsPerSec = Math.max(0, (rxBytes - root.prevRxBytes) * 8 / elapsedSec);
                        root.uploadBitsPerSec = Math.max(0, (txBytes - root.prevTxBytes) * 8 / elapsedSec);
                    }
                    root.prevRxBytes = rxBytes;
                    root.prevTxBytes = txBytes;
                }
            }
        }
    }

    Timer {
        id: statsTimer
        interval: 2000
        running: root.activeInterfaceName !== ""
        repeat: true
        triggeredOnStart: true
        onTriggered: statsProcess.running = true
    }

    // Resets the bandwidth baseline on interface changes (wifi <-> wired,
    // or reconnecting) — otherwise the first sample after a switch would
    // delta against stale byte counts from a different interface entirely.
    onActiveInterfaceNameChanged: {
        root.prevRxBytes = -1;
        root.prevTxBytes = -1;
    }

    Popups.Tooltip {
        hoverTarget: root
        hovered: mouseArea.containsMouse

        Column {
            spacing: Metrics.sizeTiny

            Text {
                visible: root.frequencyMHz > 0
                text: root.displayText.split(" (")[0] + " " + root.frequencyMHz + "MHz"
                color: Colors.textPrimary
                font.family: Fonts.currentFamily
                font.pixelSize: Fonts.small
            }
            Text {
                visible: root.signalDbm !== 0
                text: "Strength: " + root.signalDbm + "dBm (" + (root.connectedWifiNetwork ? Math.round(root.connectedWifiNetwork.signalStrength * 100) : 0) + "%)"
                color: Colors.textPrimary
                font.family: Fonts.currentFamily
                font.pixelSize: Fonts.small
            }
            Text {
                text: "IP: " + root.ipAddress
                color: Colors.textPrimary
                font.family: Fonts.currentFamily
                font.pixelSize: Fonts.small
            }
            Text {
                text: "Up: " + root.formatBits(root.uploadBitsPerSec) + "  Down: " + root.formatBits(root.downloadBitsPerSec)
                color: Colors.textPrimary
                font.family: Fonts.currentFamily
                font.pixelSize: Fonts.small
            }
        }
    }
}
