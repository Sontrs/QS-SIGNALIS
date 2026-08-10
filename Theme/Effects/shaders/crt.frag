#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(binding = 1) uniform sampler2D source;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float aberration;
    float curve;
};

vec2 curveRemapUV(vec2 uv) {
    uv = uv * 2.0 - 1.0;
    vec2 offset = abs(uv.yx) / vec2(curve, curve);
    uv = uv + uv * offset * offset;
    uv = uv * 0.5 + 0.5;
    return uv;
}

void main() {
    vec2 uv = curveRemapUV(qt_TexCoord0);

    float r = texture(source, uv + vec2(aberration, 0.0)).r;
    float g = texture(source, uv).g;
    float b = texture(source, uv - vec2(aberration, 0.0)).b;
    float a = texture(source, uv).a;

    vec4 col = vec4(r, g, b, a);

    vec2 vignetteUV = qt_TexCoord0 * (1.0 - qt_TexCoord0.yx);
    float vignette = vignetteUV.x * vignetteUV.y * 15.0;
    vignette = pow(vignette, 0.25);

    col.rgb *= vignette;

    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        col = vec4(0.0, 0.0, 0.0, 0.0);
    }

    fragColor = col * qt_Opacity;
}
