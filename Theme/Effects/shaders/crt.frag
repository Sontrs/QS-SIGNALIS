#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(binding = 1) uniform sampler2D source;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 resolution;
    float time;
    float noiseTime;
    float pixelSize;
    float curvatureEnabled;
    float curve;
    float aberrationEnabled;
    float aberration;
    float scanlineIntensity;
    float noiseIntensity;
};

vec2 curveRemapUV(vec2 uv) {
    uv = uv * 2.0 - 1.0;
    vec2 offset = abs(uv.yx) / vec2(curve, curve);
    uv = uv + uv * offset * offset;
    uv = uv * 0.5 + 0.5;
    return uv;
}

float random(vec2 co) {
    return fract(sin(dot(co.xy + noiseTime, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {
    vec2 uv = qt_TexCoord0;

    // Pixelation: snap to a coarse grid in source-texture pixels before
    // anything else samples it, so every later pass (warp, aberration,
    // scanlines, noise) reads and writes against the same blocky grid
    // instead of crisp pixelation fighting a separately-smooth scanline.
    if (pixelSize > 1.0) {
        vec2 texel = pixelSize / resolution;
        uv = (floor(uv / texel) + 0.5) * texel;
    }

    if (curvatureEnabled > 0.5) {
        uv = curveRemapUV(uv);
    }

    vec4 col;
    if (aberrationEnabled > 0.5) {
        float r = texture(source, uv + vec2(aberration, 0.0)).r;
        float g = texture(source, uv).g;
        float b = texture(source, uv - vec2(aberration, 0.0)).b;
        float a = texture(source, uv).a;
        col = vec4(r, g, b, a);
    } else {
        col = texture(source, uv);
    }

    // Vignette specifically sells "this is a curved sheet of glass," so it
    // only makes sense paired with curvature itself, not with aberration
    // alone — a flat popup with aberration but no warp shouldn't also get
    // darkened corners, that reads as a bug rather than a curved screen.
    if (curvatureEnabled > 0.5) {
        vec2 vignetteUV = qt_TexCoord0 * (1.0 - qt_TexCoord0.yx);
        float vignette = vignetteUV.x * vignetteUV.y * 15.0;
        vignette = pow(vignette, 0.25);
        col.rgb *= vignette;

        if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
            col = vec4(0.0, 0.0, 0.0, 0.0);
        }
    }

    // Scanlines and noise both multiply against the content we already
    // sampled above (real alpha included) instead of being painted as their
    // own independent full-rect layer — this is what actually fixes the old
    // hard-edge-square bug: they now fade out exactly where the source
    // content's alpha does, rather than covering the whole window rect
    // regardless of what shape is actually visible underneath.
    if (scanlineIntensity > 0.0) {
        float scanline = sin((uv.y + time * 0.01) * 800.0) * 0.5 + 0.5;
        scanline = smoothstep(0.3, 0.7, scanline);
        col.rgb *= 1.0 - (1.0 - scanline) * scanlineIntensity;
    }

    if (noiseIntensity > 0.0) {
        float n = random(uv) - 0.5;
        // Premultiplied-safe: scale the grain contribution by the content's
        // own alpha so it never adds visible noise where there's nothing to
        // show it on top of.
        col.rgb += n * noiseIntensity * col.a;
    }

    fragColor = col * qt_Opacity;
}
