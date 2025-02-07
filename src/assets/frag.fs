#version 330 core
out vec4 FragColor;

in vec2 TexCoord;

uniform sampler2DArray atlas;
uniform float texId;
uniform vec4 fg;
uniform vec4 bg;

void main()
{
    vec4 original = texture(atlas, vec3(TexCoord, texId));
    vec4 frag = original.r > 0.1f || original.g > 0.1f || original.b > 0.1f ? original * fg : bg;
	FragColor = frag;
}
