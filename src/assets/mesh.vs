#version 330 core
layout (location = 0) in vec3 aPos;    
layout (location = 1) in vec3 aNorm; 
layout (location = 2) in vec3 aFg; 
layout (location = 3) in vec3 aBg; 
layout (location = 4) in vec2 aTexCoords; 

out vec2 texCoords;
out vec3 norm;
out vec3 fg;
out vec3 bg;

uniform vec3 offsets[100];
uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

void main() {
    vec3 offset = offsets[gl_InstanceID];
    vec4 worldPos = model * vec4(aPos + offset, 1.0);

    texCoords = aTexCoords;
    norm = aNorm;
    fg = aFg;
    bg = aBg;
    gl_Position = projection * view * worldPos;

}
