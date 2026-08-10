#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
};

float random(vec2 co) {
    return fract(sin(dot(co.xy + time, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {
    float noise = random(qt_TexCoord0);
    float a = qt_Opacity;
    // Qt Quick expects premultiplied alpha output — rgb must already be
    // scaled by a. Leaving rgb at full 0-1 contrast against a small
    // separate alpha (the old version) reads as near-full-strength static
    // almost regardless of the intensity/opacity setting.
    fragColor = vec4(noise * a, noise * a, noise * a, a);
}
