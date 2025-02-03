#version 330 core
out vec4 FragColor;

in vec4 ourFGColor;
in vec4 ourBGColor;
in vec2 TexCoord;

uniform sampler2D ourTexture;

void main()
{
   vec4 original = texture(ourTexture, TexCoord);
    vec4 fg = original.r > 0.1f || original.g > 0.1f || original.b > 0.1f ? original * vec4(ourFGColor) : vec4(ourBGColor);
	FragColor = fg;
}
