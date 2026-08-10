import QtQuick

// Random grain/static, refreshed on a timer rather than a smooth animation
// to keep the "old CRT" flicker feel rather than looking like smooth video
// noise.
ShaderEffect {
    id: root
    property real intensity: 0.08
    property int refreshIntervalMs: 50
    property real time: 0

    opacity: root.intensity

    Timer {
        interval: root.refreshIntervalMs
        running: true
        repeat: true
        onTriggered: root.time = Math.random() * 1000
    }

    // GLSL source in shaders/noise.frag, compiled to shaders/noise.frag.qsb
    // — recompile with:
    //   qsb --glsl "100 es,120,150,300 es,320 es,330,440" --hlsl 50 \
    //       --msl 12 -o shaders/noise.frag.qsb shaders/noise.frag
    fragmentShader: "shaders/noise.frag.qsb"
}
