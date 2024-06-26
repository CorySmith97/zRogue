#version 330 core
out vec4 FragColor;
  
in vec3 ourFGColor;
in vec3 ourBGColor;
in vec2 TexCoord;

uniform sampler2D ourTexture;

void main()
{
   vec4 original = texture(ourTexture, TexCoord);
    vec4 fg = original.r > 0.1f || original.g > 0.1f || original.b > 0.1f ? original * vec4(ourFGColor, 1.f) : vec4(ourBGColor, 1.f);
	FragColor = fg;
}
