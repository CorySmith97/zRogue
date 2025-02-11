#version 330 core
out vec4 FragColor;

in vec2 TexCoord;

uniform sampler2D ourTexture;
uniform float texId;
uniform vec4 fg;
uniform vec4 bg;
uniform vec2 sprite_size;
uniform vec2 atlas_size;

void main()
{
    float sprites_per_row = atlas_size.x / sprite_size.x;
    float row = floor(texId / sprites_per_row);
    float col = mod(texId, sprites_per_row);

    vec2 sprite_offset = vec2(col * sprite_size.x, row * sprite_size.y);
    vec2 fixedTexCoord = vec2(1.0 - TexCoord.y, 1.0 - TexCoord.x);

    vec2 sprite_uv = (sprite_offset + fixedTexCoord * sprite_size) / atlas_size;

    vec4 original = texture(ourTexture, sprite_uv);

    vec4 finalColor = (original.r > 0.1 || original.g > 0.1 || original.b > 0.1)
                        ? original * fg
                        : bg;

    FragColor = finalColor;
}

