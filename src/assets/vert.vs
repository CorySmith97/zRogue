#version 330 core
layout (location = 0) in vec2 aPos;
layout (location = 1) in vec3 fgColor;
layout (location = 2) in vec3 bgColor;
layout (location = 3) in vec2 aTexCoord;

out vec3 ourFGColor;
out vec3 ourBGColor;
out vec2 TexCoord;

void main()
{
    gl_Position = vec4(aPos, 0.0, 1.0);
    ourFGColor = fgColor;
    ourBGColor = bgColor;
    TexCoord = aTexCoord;
}
