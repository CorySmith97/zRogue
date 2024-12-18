#version 330 core
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 fgColor;
layout (location = 2) in vec3 bgColor;
layout (location = 3) in vec2 aTexCoord;

out vec3 ourFGColor;
out vec3 ourBGColor;
out vec2 TexCoord;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

void main()
{
    gl_Position = projection * view * model * vec4(aPos, 1.0);
    ourFGColor = fgColor;
    ourBGColor = bgColor;
    TexCoord = aTexCoord;
}
