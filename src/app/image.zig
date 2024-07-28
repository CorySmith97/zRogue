const std = @import("std");
const c = @import("c.zig");
const bmp = @import("bmp.zig");

const Self = @This();
width: usize,
height: usize,
data: []const u8,

pub fn initFromBmp(b: bmp) Self {
    return .{
        .width = b.width,
        .height = b.height,
        .data = b.raw[0 .. b.height * b.width],
    };
}
/// Moves the image to an opengl texture and passes it to the GPU
pub fn imgToTexture(image: *Self) !c.GLuint {
    var texture: u32 = undefined;
    c.glGenTextures(1, &texture);
    c.glBindTexture(c.GL_TEXTURE_2D, texture);
    // set the texture wrapping/filtering options (on the currently bound texture object)
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_S, c.GL_CLAMP_TO_EDGE);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_T, c.GL_CLAMP_TO_EDGE);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MIN_FILTER, c.GL_NEAREST_MIPMAP_NEAREST);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MAG_FILTER, c.GL_NEAREST);
    c.glPixelStorei(c.GL_PACK_ALIGNMENT, 1);

    c.glTexImage2D(
        c.GL_TEXTURE_2D,
        0,
        c.GL_RGB,
        @intCast(image.width),
        @intCast(image.height),
        0,
        c.GL_RGB,
        c.GL_UNSIGNED_BYTE,
        @ptrCast(image.data),
    );
    c.glGenerateMipmap(c.GL_TEXTURE_2D);

    return texture;
}
