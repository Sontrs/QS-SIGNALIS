import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../../Theme"

// Pipewire is socket-based and push-driven like UPower — no Timer or
// Process polling needed.
//
// PwObjectTracker below is required, not optional — per Quickshell's own
// docs, a node's properties (including .audio) stay invalid until it's
// explicitly bound this way. Easy to miss, confirmed against a real
// working example rather than assumed.
//
// volume is a 0-1+ fraction (1.0 = 100%, can go higher for amplification
// past "normal"), multiplied by 100 for display — learned the
// fraction-vs-percentage lesson from battery already, applied here
// before it became a live bug instead of after.
//
// Left-click opens pavucontrol, right-click toggles mute — both
// confirmed from the actual config, though mute-toggle uses Pipewire's
// own native audio.muted property directly rather than replicating the
// config's literal "amixer sset Master toggle 1" ALSA command, since a
// cleaner native path already exists here (same reasoning as using
// UPower/Pipewire themselves instead of shelling out to upower/wpctl
// elsewhere).
//
// Scroll-to-adjust IS included despite the config's own on-scroll-up/
// on-scroll-down lines being commented out — turns out waybar's
// pulseaudio/wireplumber module has scroll-adjust built in by default,
// and those config lines only exist to override that default with a
// custom command. Since they're unset, the module just falls back to its
// own built-in behavior, which is why it kept working. 5% per notch,
// clamped to 0-100% (not allowed to scroll past 100% into amplification
// territory), matching what was actually observed live rather than the
// config text alone.
Rectangle {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property real volumePercent: (sink?.audio?.volume ?? 0) * 100

    PwObjectTracker {
        objects: [root.sink]
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
        text: "A" + (root.muted ? "MUTE" : (Math.round(root.volumePercent) + "%"))
        color: Colors.textPrimary
        font.family: Fonts.currentFamily
        font.pixelSize: Fonts.body
    }

    function adjustVolume(deltaPercent) {
        if (!root.sink?.audio)
            return;
        const current = root.sink.audio.volume;
        const next = Math.max(0, Math.min(1.0, current + deltaPercent / 100));
        root.sink.audio.volume = next;
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton) {
                Quickshell.execDetached(["pavucontrol"]);
            } else if (root.sink?.audio) {
                root.sink.audio.muted = !root.sink.audio.muted;
            }
        }
        onWheel: event => root.adjustVolume(event.angleDelta.y > 0 ? 5 : -5)
    }
}
