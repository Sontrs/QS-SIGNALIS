import QtQuick

// Shared "CRT material" — bundles CRTOverlay (curvature/aberration) +
// ScanlinesOverlay + NoiseOverlay + FlickerOverlay behind one `strength`
// knob, so every surface that wants the look layers the same four passes
// instead of re-composing them (and drifting apart) like WLogout used to
// do inline. Same consolidation reasoning as CutFrame replacing four shape
// files: one source of truth for "the CRT look."
//
// Curvature and flicker are each independently toggleable per surface —
// not every panel that wants the scanline/grain texture also wants a
// warped, occasionally-flashing screen. A small floating popup doesn't
// read as "an old monitor" the way a fullscreen takeover does; curving it
// just looks like a lens bulge, and a random white flash on something
// meant to be quickly skimmed reads as a bug, not mood.
Item {
    id: root

    // Content to distort. Only consumed when curvatureEnabled is true —
    // CRTOverlay's ShaderEffectSource hides whatever sourceItem it's
    // bound to (to redraw it warped instead), so this is deliberately left
    // unbound rather than just visually hidden when curvature is off:
    // binding it regardless would hide the real content with nothing
    // there to replace it, per CRTOverlay's own sourceItem doc.
    property Item sourceItem

    // Master 0-1 knob. Scales aberration/scanlines/noise together so a
    // caller can dial the whole look up or down without touching each
    // overlay's own tuned defaults.
    property real strength: 1.0

    property bool curvatureEnabled: true
    property bool flickerEnabled: true

    property real aberration: 0.002 * root.strength
    // curve is a divisor (see CRTOverlay) — smaller = stronger warp. Lower
    // strength pushes curve UP toward "nearly flat" rather than scaling it
    // down directly, since scaling a divisor down would make a *subtler*
    // surface warp *harder*. At strength 1.0 this lands exactly on
    // CRTOverlay's own default (8.0).
    property real curve: 8.0 + (1.0 - root.strength) * 24.0

    property real scanlineIntensity: 0.15 * root.strength
    property real noiseIntensity: 0.08 * root.strength

    CRTOverlay {
        anchors.fill: parent
        visible: root.curvatureEnabled
        sourceItem: root.curvatureEnabled ? root.sourceItem : null
        aberration: root.aberration
        curve: root.curve
        z: 2
    }

    ScanlinesOverlay {
        anchors.fill: parent
        intensity: root.scanlineIntensity
        z: 3
    }

    NoiseOverlay {
        anchors.fill: parent
        intensity: root.noiseIntensity
        z: 4
    }

    FlickerOverlay {
        anchors.fill: parent
        visible: root.flickerEnabled
        z: 5
    }
}
