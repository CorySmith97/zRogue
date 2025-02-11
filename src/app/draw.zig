const std = @import("std");
const c = @import("c.zig");
const Shader = @import("shader.zig");
const Camera = @import("camera.zig").Camera2D;

pub fn checkGLError() void {
    const err = c.glGetError();
    if (err != c.GL_NO_ERROR) {
        std.debug.print("OpenGL error: {}\n", .{err});
    }
}

const SpriteConstants = struct {
    h_tile_size: f32 = 80,
    v_tile_size: f32 = 50,
    screen_width: i32 = 1200,
    screen_height: i32 = 800,
};

pub var sprite_constants: SpriteConstants = .{};
pub var VaoBuffer: Buffers = undefined;

/// simple RGB struct. Colors are between 0.0 and 1.0.
pub const Color = struct {
    r: f32,
    g: f32,
    b: f32,
    a: f32 = 1.0,
};

pub const AnimationFrame = struct {
    fg: Color,
    bg: Color,
    char: u8,
};

pub const Animation = struct {
    frames: []AnimationFrame,
    cur_frame: u32 = 0,
    font_size: f32 = 1,
    frame_speed: u32,
    frame_count: u32,
    x: f32,
    y: f32,

    pub fn draw(self: *Animation) void {
        if (self.frame_count == self.frame_speed) {
            self.frame_count = 0;
            self.cur_frame = (self.cur_frame + 1) % @as(u32, @intCast(self.frames.len));
        } else {
            self.frame_count += 1;
        }
        const frame = self.frames[@intCast(self.cur_frame)];
        drawSpriteC(self.x, self.y, frame.fg, frame.bg, frame.char, self.font_size);
    }
};

const Buffers = struct {
    vao: u32,
    vbo: u32,
    ebo: u32,
    shd_ui: *Shader,
    shd_basic: *Shader,

    pub fn deinit(self: *@This()) void {
        c.glDeleteVertexArrays(1, &self.vao);
        c.glDeleteBuffers(1, &self.vbo);
        c.glDeleteBuffers(1, &self.ebo);
    }
};

pub const WHITE = Color{ .r = 1.0, .g = 1.0, .b = 1.0 };
pub const GRAY = Color{ .r = 0.75, .g = 0.75, .b = 0.75 };
pub const BLACK = Color{ .r = 0.0, .g = 0.0, .b = 0.0 };
pub const GREEN = Color{ .r = 0.0, .g = 1.0, .b = 0.0 };
pub const MAGENTA = Color{ .r = 0.8, .g = 0.0, .b = 0.35 };
pub const PURPLE = Color{ .r = 1.0, .g = 0.0, .b = 1.0 };
pub const MUSTARD = Color{ .r = 0.9, .g = 0.65, .b = 0.07 };
pub const YELLOW = Color{ .r = 1.0, .g = 1.0, .b = 0.0 };
pub const ORANGE = Color{ .r = 1.0, .g = 0.65, .b = 0.0 };
pub const TEAL = Color{ .r = 0.0, .g = 1.0, .b = 0.875 };
pub const DARK_BLUE = Color{ .r = 0.070, .g = 0.375, .b = 0.333 };
pub const PASTEL_GREEN = Color{ .r = 0.575, .g = 0.9, .b = 0.75 };
pub const PASTEL_PINK = Color{ .r = 0.9, .g = 0.575, .b = 0.7 };
pub const PASTEL_RED = Color{ .r = 0.95, .g = 0.575, .b = 0.575 };
pub const PASTEL_PURPLE = Color{ .r = 0.9, .g = 0.575, .b = 0.9 };
pub const PASTEL_BLUE = Color{ .r = 0.575, .g = 0.77, .b = 0.9 };
pub const PASTEL_YELLOW = Color{ .r = 0.9, .g = 0.9, .b = 0.575 };
pub const PASTEL_ORANGE = Color{ .r = 0.9, .g = 0.75, .b = 0.575 };
pub const TRANSPARENT = Color{ .r = 0, .g = 0, .b = 0, .a = 0 };

const indices = [_][3]u32{
    [_]u32{ 0, 1, 2 },
    [_]u32{ 0, 2, 3 },
};
const verts = [_][4]f32{
    [_]f32{ 0.0, 1.0, 0, 1 },
    [_]f32{ 1.0, 1.0, 0, 0 },
    [_]f32{ 1.0, 0.0, 1, 0 },
    [_]f32{ 0.0, 0.0, 1, 1 },
};
pub fn makeVao(shader: *Shader, shader_basic: *Shader) void {
    var vao: c_uint = undefined;
    c.glGenVertexArrays(1, &vao);
    c.glBindVertexArray(vao);

    var vbo: u32 = 0;
    c.glGenBuffers(1, &vbo);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
    c.glBufferData(
        c.GL_ARRAY_BUFFER,
        verts.len * verts[0].len * @sizeOf(c.GLfloat),
        &verts,
        c.GL_STATIC_DRAW,
    );
    var ebo: u32 = 0;
    c.glGenBuffers(1, &ebo);
    c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, ebo);
    c.glBufferData(
        c.GL_ELEMENT_ARRAY_BUFFER,
        6 * @sizeOf(u32),
        &indices,
        c.GL_STATIC_DRAW,
    );
    const c_offset = @as(?*anyopaque, @ptrFromInt(0));

    c.glVertexAttribPointer(
        0,
        2,
        c.GL_FLOAT,
        c.GL_FALSE,
        4 * @sizeOf(f32),
        c_offset,
    );
    c.glEnableVertexAttribArray(0);

    const tex_offset = @as(?*anyopaque, @ptrFromInt(2 * @sizeOf(f32)));
    c.glVertexAttribPointer(
        1,
        2,
        c.GL_FLOAT,
        c.GL_FALSE,
        4 * @sizeOf(f32),
        tex_offset,
    );
    c.glEnableVertexAttribArray(1);

    VaoBuffer = .{
        .vao = vao,
        .ebo = ebo,
        .vbo = vbo,
        .shd_ui = shader,
        .shd_basic = shader_basic,
    };
}

// ---------------------------------------------
// UI based functions:
// These function do not use an mvp to draw, but
// rather draw to a top layer based on screen
// pos.

pub fn drawSpriteC(
    cell_x: f32,
    cell_y: f32,
    fg: Color,
    bg: Color,
    ascii_ch: u32,
    font_size: f32,
) void {
    VaoBuffer.shd_ui.setColor("fg", fg);
    VaoBuffer.shd_ui.setColor("bg", bg);
    VaoBuffer.shd_ui.set2Float("position", @constCast(&[_]f32{ cell_x, cell_y }));
    VaoBuffer.shd_ui.setFloat("scalar", font_size);
    VaoBuffer.shd_ui.setFloat("texId", @floatFromInt(ascii_ch));
    c.glBindVertexArray(VaoBuffer.vao);
    c.glDrawElements(c.GL_TRIANGLES, 6, c.GL_UNSIGNED_INT, null);
}

/// Draws a simple sprite at a given location. The cells are on a 80x50 grid.
pub fn drawSprite(cell_x: f32, cell_y: f32, fg: Color, bg: Color, ascii_ch: u32) void {
    VaoBuffer.shd_ui.setColor("fg", fg);
    VaoBuffer.shd_ui.setColor("bg", bg);
    VaoBuffer.shd_ui.set2Float("position", @constCast(&[_]f32{ cell_x, cell_y }));
    VaoBuffer.shd_ui.setFloat("scalar", 1);
    VaoBuffer.shd_ui.setFloat("texId", @floatFromInt(ascii_ch));
    c.glBindVertexArray(VaoBuffer.vao);
    c.glDrawElements(c.GL_TRIANGLES, 6, c.GL_UNSIGNED_INT, null);
}

pub fn drawSpriteAsciiC(
    cell_x: f32,
    cell_y: f32,
    fg: Color,
    bg: Color,
    ascii_ch: u8,
    font_size: f32,
) void {
    VaoBuffer.shd_ui.setColor("fg", fg);
    VaoBuffer.shd_ui.setColor("bg", bg);
    VaoBuffer.shd_ui.set2Float("position", @constCast(&[_]f32{ cell_x, cell_y }));
    VaoBuffer.shd_ui.setFloat("scalar", font_size);
    VaoBuffer.shd_ui.setFloat("texId", @floatFromInt(ascii_ch));
    c.glBindVertexArray(VaoBuffer.vao);
    c.glDrawElements(c.GL_TRIANGLES, 6, c.GL_UNSIGNED_INT, null);
}

/// Draws a simple sprite at a given location. The cells are on a 80x50 grid.
pub fn drawSpriteAscii(cell_x: f32, cell_y: f32, fg: Color, bg: Color, ascii_ch: u8) void {
    VaoBuffer.shd_ui.setColor("fg", fg);
    VaoBuffer.shd_ui.setColor("bg", bg);
    VaoBuffer.shd_ui.set2Float("position", @constCast(&[_]f32{ cell_x, cell_y }));
    VaoBuffer.shd_ui.setFloat("scalar", 1);
    VaoBuffer.shd_ui.setFloat("texId", @floatFromInt(ascii_ch));
    c.glBindVertexArray(VaoBuffer.vao);
    c.glDrawElements(c.GL_TRIANGLES, 6, c.GL_UNSIGNED_INT, null);
}

// This draw with the start_y being the lower of the two values
pub fn drawVertLine(x: f32, start_y: f32, end_y: f32, fg: Color, bg: Color) void {
    const su: usize = @intFromFloat(start_y);
    const eu: usize = @intFromFloat(end_y);
    for (su..eu) |y| {
        print(x, @floatFromInt(y), fg, bg, &[_]u8{179});
    }
}

pub fn drawHorzLine(y: f32, start_x: f32, end_x: f32, fg: Color, bg: Color) void {
    const su: usize = @intFromFloat(start_x);
    const eu: usize = @intFromFloat(end_x);
    for (su..eu) |x| {
        print(@floatFromInt(x), y, fg, bg, &[_]u8{196});
    }
}

pub fn drawBox(
    x_min: f32,
    x_max: f32,
    y_min: f32,
    y_max: f32,
    fg: Color,
    bg: Color,
) void {
    drawHorzLine(y_min, x_min + 1, x_max, fg, bg);
    drawHorzLine(y_max, x_min + 1, x_max, fg, bg);
    drawVertLine(x_min, y_min + 1, y_max, fg, bg);
    drawVertLine(x_max, y_min + 1, y_max, fg, bg);
    drawSpriteAscii(x_min, y_min, fg, bg, 218);
    drawSpriteAscii(x_max, y_max, fg, bg, 217);
    drawSpriteAscii(x_min, y_max, fg, bg, 192);
    drawSpriteAscii(x_max, y_min, fg, bg, 191);
}

/// Prints a string to the screen. It starts at the given cell_position, and will
/// wrap around to the next row.
pub fn print(cell_x: f32, cell_y: f32, fg: Color, bg: Color, string: []const u8) void {
    var x_position = cell_x;
    for (string) |char| {
        drawSpriteAscii(x_position, cell_y, fg, bg, char);
        x_position += 1;
    }
}

pub fn printC(
    cell_x: f32,
    cell_y: f32,
    fg: Color,
    bg: Color,
    string: []const u8,
    font_size: f32,
) void {
    var x_position = cell_x;
    for (string) |char| {
        drawSpriteAsciiC(x_position, cell_y, fg, bg, char, font_size);
        x_position += 1 * font_size;
    }
}

// ---------------------------------------------

pub fn drawSpriteCameraC(
    camera: *Camera,
    cell_x: f32,
    cell_y: f32,
    fg: Color,
    bg: Color,
    ascii_ch: u32,
    font_size: f32,
) void {
    const model = Camera.translateIdentity(.{ cell_x, cell_y, 0 });
    const m = Camera.scaleMat4(model, font_size);
    VaoBuffer.shd_basic.setMat4("projection", camera.projection_matrix);
    VaoBuffer.shd_basic.setMat4("model", m);
    VaoBuffer.shd_basic.setColor("fg", fg);
    VaoBuffer.shd_basic.setColor("bg", bg);
    //VaoBuffer.shd_basic.set2Float("position", @constCast(&[_]f32{ cell_x, cell_y }));
    //VaoBuffer.shd_basic.setFloat("scalar", 1);
    VaoBuffer.shd_basic.setFloat("texId", @floatFromInt(ascii_ch));
    c.glBindVertexArray(VaoBuffer.vao);
    c.glDrawElements(c.GL_TRIANGLES, 6, c.GL_UNSIGNED_INT, null);
}

pub fn drawSpriteCamera(
    camera: *Camera,
    cell_x: f32,
    cell_y: f32,
    fg: Color,
    bg: Color,
    ascii_ch: u32,
) void {
    VaoBuffer.shd_basic.set2Float("offset", @constCast(&camera.offset));
    VaoBuffer.shd_basic.setColor("fg", fg);
    VaoBuffer.shd_basic.setColor("bg", bg);
    VaoBuffer.shd_basic.set2Float("position", @constCast(&[_]f32{ cell_x, cell_y }));
    VaoBuffer.shd_basic.setFloat("scalar", 1);
    VaoBuffer.shd_basic.setFloat("texId", @floatFromInt(ascii_ch));
    c.glBindVertexArray(VaoBuffer.vao);
    c.glDrawElements(c.GL_TRIANGLES, 6, c.GL_UNSIGNED_INT, null);
}

pub fn drawTestSprite(camera: *Camera) void {
    _ = camera;
    VaoBuffer.shd_basic.set2Float("position", @constCast(&[_]f32{ 10, 10 }));
    //VaoBuffer.shd_basic.set2Float("offset", &camera.offset);
    VaoBuffer.shd_basic.setColor("fg", WHITE);
    VaoBuffer.shd_basic.setColor("bg", BLACK);
    VaoBuffer.shd_basic.setFloat("scalar", 1);
    VaoBuffer.shd_basic.setFloat("texId", 3);

    // Draw a larger sprite to make it easier to see
    c.glBindVertexArray(VaoBuffer.vao);
    c.glDrawElements(c.GL_TRIANGLES, 6, c.GL_UNSIGNED_INT, null);
    checkGLError();
}
