const std = @import("std");
const c = @cImport({
    @cInclude("stb_image.h");
    @cInclude("epoxy/gl.h");
});

const Self = @This();
width: usize,
height: usize,
data: []const u8,

pub fn init(path: [:0]const u8) !Self {
    var width: c_int = undefined;
    var height: c_int = undefined;
    var num_channels: c_int = undefined;
    c.stbi_set_flip_vertically_on_load(1);
    const data = c.stbi_load(path, &width, &height, &num_channels, 0) orelse {
        std.log.err("Failed to load image: {s}\n", .{path});
        return error.FailedImage;
    };

    return .{
        .width = @intCast(width),
        .height = @intCast(height),
        .data = data[0..@intCast(width * height)],
    };
}
pub fn imgToTexture(image: *Self) !c.GLuint {
    var texture: u32 = undefined;
    c.glGenTextures(1, &texture);
    c.glBindTexture(c.GL_TEXTURE_2D, texture);
    // set the texture wrapping/filtering options (on the currently bound texture object)
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_S, c.GL_REPEAT);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_T, c.GL_REPEAT);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MIN_FILTER, c.GL_NEAREST_MIPMAP_NEAREST);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MAG_FILTER, c.GL_NEAREST);

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

pub fn free(self: *Self) void {
    c.stbi_image_free(@ptrCast(@constCast(self.data)));
}
