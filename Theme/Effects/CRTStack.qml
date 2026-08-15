import QtQuick

// Shared "CRT material" — one content-aware shader pass bundling curvature,
// chromatic aberration + vignette, scanlines, grain, and optional
// pixelation behind a single `strength` knob, plus FlickerOverlay layered
// on top (kept separate — a plain white-flash Rectangle, not something
// that benefits from living inside the shader, and it's off everywhere
// right now anyway).
//
// This used to be four separate passes: CRTOverlay (curvature/aberration),
// ScanlinesOverlay, NoiseOverlay, FlickerOverlay. Scanlines/noise never
// took a sourceItem at all — they painted their pattern across the entire
// window rect with no idea what shape the content underneath actually was.
// That's what caused the hard-edged rectangle visible past the launcher's
// actual panel shape. It's also why aberration only ever worked on
// WLogout: it lived inside CRTOverlay, which was only instantiated when
// curvatureEnabled was true, so disabling curvature elsewhere (correctly,
// to avoid a lens-bulge look on small surfaces) silently took aberration
// down with it too.
//
// Now everything but flicker samples the same content texture once, in the
// same warped UV space, so scanlines/noise/aberration all fade out exactly
// where the source content's own alpha does — and curvature and aberration
// are independent toggles instead of a package deal.
Item {
    id: root

    // Content to distort. Always sampled now (previously only consumed
    // when curvatureEnabled was true) — every effect below needs real
    // content alpha to know where it's allowed to draw.
    property Item sourceItem

    // Master 0-1 knob. Scales aberration/scanlines/noise together so a
    // caller can dial the whole look up or down without touching each
    // effect's own tuned defaults.
    property real strength: 1.0

    property bool curvatureEnabled: true
    property bool aberrationEnabled: true
    property bool flickerEnabled: true

    // Off by default — new, untested addition (see chat: borrowed from
    // looking at L-STERNCHEN's shader). Flip true per-surface to compare
    // before deciding it's part of the look everywhere. WLogout is the
    // easiest place to judge first since it's fullscreen.
    property bool pixelationEnabled: false
    property real pixelSize: 4.0

    property real aberration: 0.002 * root.strength
    // curve is a divisor (see crt.frag) — smaller = stronger warp. Lower
    // strength pushes curve UP toward "nearly flat" rather than scaling it
    // down directly, since scaling a divisor down would make a *subtler*
    // surface warp *harder*. At strength 1.0 this lands exactly on
    // crt.frag's own tuned default (8.0).
    property real curve: 8.0 + (1.0 - root.strength) * 24.0

    property real scanlineIntensity: 0.15 * root.strength
    property real noiseIntensity: 0.08 * root.strength

    ShaderEffectSource {
        id: contentLayer
        anchors.fill: parent
        sourceItem: root.sourceItem
        hideSource: true
        visible: false
    }

    ShaderEffect {
        id: effect
        anchors.fill: parent

        property variant source: contentLayer
        property vector2d resolution: Qt.vector2d(width, height)
        property real time: 0
        property real noiseTime: 0

        property real pixelSize: root.pixelationEnabled ? root.pixelSize : 0
        property real curvatureEnabled: root.curvatureEnabled ? 1.0 : 0.0
        property real curve: root.curve
        property real aberrationEnabled: root.aberrationEnabled ? 1.0 : 0.0
        property real aberration: root.aberration
        property real scanlineIntensity: root.scanlineIntensity
        property real noiseIntensity: root.noiseIntensity

        // Continuous scroll for scanlines — same rate as the old
        // ScanlinesOverlay used (0 to 100 over 10s → time*0.01 in the
        // shader), kept identical rather than re-tuned.
        NumberAnimation on time {
            running: root.scanlineIntensity > 0
            from: 0
            to: 100
            duration: 10000
            loops: Animation.Infinite
        }

        // Noise deliberately jumps on a timer rather than animating
        // smoothly — that's what reads as old-CRT static rather than
        // smooth video grain. Same 50ms interval as the old NoiseOverlay.
        Timer {
            interval: 50
            running: root.noiseIntensity > 0
            repeat: true
            onTriggered: effect.noiseTime = Math.random() * 1000
        }

        // GLSL source in shaders/crt.frag, compiled to shaders/crt.frag.qsb
        // via Qt's qsb tool. Recompile after editing with:
        //   qsb --glsl "100 es,120,150,300 es,320 es,330,440" --hlsl 50 \
        //       --msl 12 -o shaders/crt.frag.qsb shaders/crt.frag
        fragmentShader: "shaders/crt.frag.qsb"
    }

    FlickerOverlay {
        anchors.fill: parent
        visible: root.flickerEnabled
        z: 5
    }
}
