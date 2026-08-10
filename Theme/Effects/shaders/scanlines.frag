#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
};

void main() {
    float scanline = sin((qt_TexCoord0.y + time * 0.01) * 800.0) * 0.5 + 0.5;
    scanline = smoothstep(0.3, 0.7, scanline);
    fragColor = vec4(0.0, 0.0, 0.0, (1.0 - scanline) * qt_Opacity);
}
