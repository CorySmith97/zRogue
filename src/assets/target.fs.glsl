#version 330 core

out vec4 FragColor;

uniform sampler2D atlasTexture;

in vec2 texCoords; 
in vec3 norm; 
in vec3 fg;
in vec3 bg;

void main() {
    vec4 original = texture(atlasTexture, texCoords);
    vec4 color = original.r > 0.1f || original.g > 0.1f || original.b > 0.1f ? original * vec4(fg, 1.f) : vec4(bg, 0.f);
	FragColor = color;
}
