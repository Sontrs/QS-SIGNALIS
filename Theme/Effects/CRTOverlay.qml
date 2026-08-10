import QtQuick

// Wraps sourceItem in curvature + chromatic aberration + vignette + edge
// fade, as one combined shader pass. Curvature/aberration/vignette are kept
// bundled rather than split into separately chainable effects: they're
// always wanted together as "the CRT look," and separate passes would each
// cost an extra offscreen render for a modularity benefit nobody needs.
Item {
    id: root

    property Item sourceItem
    property real aberration: 0.002
    // curve is a divisor in curveRemapUV below (offset = |uv|/curve), not a
    // 0-1 "strength" — a small value here produces a huge offset that gets
    // squared, blowing coordinates outside the valid range almost
    // everywhere except dead-center. 6-10 gives a subtle screen curve;
    // anything under ~2 will look like a funnel/vortex.
    property real curve: 8.0

    ShaderEffectSource {
        id: contentLayer
        anchors.fill: parent
        sourceItem: root.sourceItem
        hideSource: true
        visible: false
    }

    ShaderEffect {
        anchors.fill: parent

        property variant source: contentLayer
        property real aberration: root.aberration
        property real curve: root.curve

        // Note: the original version of this shader declared a "time"
        // uniform driven by an infinite NumberAnimation, but never actually
        // used it anywhere in the GLSL logic below — dead animation, removed.
        //
        // GLSL source is in shaders/crt.frag, compiled to shaders/crt.frag.qsb
        // via Qt's qsb tool — Qt6 ShaderEffect requires a precompiled .qsb
        // URL, not a raw GLSL string. Recompile after editing the .frag with:
        //   qsb --glsl "100 es,120,150,300 es,320 es,330,440" --hlsl 50 \
        //       --msl 12 -o shaders/crt.frag.qsb shaders/crt.frag

        fragmentShader: "../Effects/shaders/crt.frag.qsb"
    }
}
