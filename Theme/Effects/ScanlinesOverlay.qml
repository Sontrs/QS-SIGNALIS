import QtQuick

// Slowly scrolling scanline pattern. Independent of CRTOverlay so it can be
// toggled on its own (e.g. wanted without noise/grain).
ShaderEffect {
    id: root
    property real intensity: 0.15
    property real time: 0

    opacity: root.intensity

    NumberAnimation on time {
        from: 0
        to: 100
        duration: 10000
        loops: Animation.Infinite
    }

    // GLSL source in shaders/scanlines.frag, compiled to
    // shaders/scanlines.frag.qsb — recompile with:
    //   qsb --glsl "100 es,120,150,300 es,320 es,330,440" --hlsl 50 \
    //       --msl 12 -o shaders/scanlines.frag.qsb shaders/scanlines.frag
    fragmentShader: "shaders/scanlines.frag.qsb"
}
