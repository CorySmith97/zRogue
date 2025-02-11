#version 330 core
layout (location = 0) in vec2 aPos;
layout (location = 1) in vec2 aTexCoord;

out vec2 TexCoord;
uniform vec2 position;
uniform vec2 offset;
uniform float scalar;

void main() {
    float cellWidth  = 2.0 / 80.0;
    float cellHeight = 2.0 / 50.0;

    float originX = position.x * cellWidth - 1.0;
    float originY = position.y * cellHeight - 1.0;

    float ndcX = originX + aPos.x * cellWidth * scalar;
    float ndcY = originY + aPos.y * cellHeight * scalar;

    gl_Position = vec4(ndcX + offset.x, -ndcY + offset.y, 0.0, 1.0);
    TexCoord = aTexCoord;
}
