import QtQuick

// A small scrolling heartbeat-monitor-style waveform. periodMs controls how
// long one full pulse cycle takes — lower urgency notifications get a slow,
// calm pulse; higher urgency gets a fast, frantic one. Bespoke to
// Notifications (not part of the shared Components/ tree) since nothing
// else in the shell needs an ECG line.
Item {
    id: root

    property color lineColor: "white"
    property real strokeWidth: 1.5
    property int periodMs: 1000

    // Normalized single heartbeat cycle: small P-wave bump, sharp QRS
    // spike, gentler T-wave, then flat baseline before repeating.
    readonly property var pattern: [
        0.0, 0.0, 0.05, -0.08, 0.0, 0.0,
        0.0, -0.15, 0.95, -0.55, 0.15, 0.0,
        0.0, 0.12, 0.18, 0.08, 0.0,
        0.0, 0.0, 0.0, 0.0
    ]

    property real phase: 0

    NumberAnimation on phase {
        from: 0
        to: 1
        duration: root.periodMs
        loops: Animation.Infinite
        running: true
    }

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.strokeStyle = root.lineColor;
            ctx.lineWidth = root.strokeWidth;
            ctx.beginPath();

            const pts = root.pattern;
            const n = pts.length;
            const cyclesVisible = 2;
            const totalSteps = n * cyclesVisible;

            for (let i = 0; i <= totalSteps; i++) {
                const shifted = i + root.phase * n;
                const idx = Math.floor(shifted) % n;
                const val = pts[idx];
                const x = (i / totalSteps) * width;
                const y = height / 2 - val * (height / 2 - 2);
                if (i === 0)
                    ctx.moveTo(x, y);
                else
                    ctx.lineTo(x, y);
            }

            ctx.stroke();
        }

        Connections {
            target: root
            function onPhaseChanged() {
                canvas.requestPaint();
            }
        }
    }
}
