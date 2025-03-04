const std = @import("std");
const c = @import("c.zig");
const Shader = @import("shader.zig");

const rootstate = @import("../root.zig").rootstate;

/// TODO: Im going to begin instancing, or using the same vao for everythin.
/// The idea will be use uniforms to determine which sprite will be rendered.
pub const SpriteConstants = struct {
    h_tile_size: f32 = 80,
    v_tile_size: f32 = 50,
    screen_width: i32 = 1200,
    screen_height: i32 = 800,
};

pub var VaoBuffer: Buffers = undefined;
pub var sprite_constants: SpriteConstants = .{};

pub fn initBuffers() void {}

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
    shd: *Shader,

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
    [_]f32{ -0.5, 0.5, 0, 1 },
    [_]f32{ -0.5, -0.5, 0, 0 },
    [_]f32{ 0.5, -0.5, 1, 0 },
    [_]f32{ 0.5, 0.5, 1, 1 },
};
pub fn makeVao(shader: *Shader) void {
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

    VaoBuffer = .{ .vao = vao, .ebo = ebo, .vbo = vbo, .shd = shader };
}

pub fn drawSpriteC(
    cell_x: f32,
    cell_y: f32,
    fg: Color,
    bg: Color,
    ascii_ch: u8,
    font_size: f32,
) void {
    VaoBuffer.shd.setColor("fg", fg);
    VaoBuffer.shd.setColor("bg", bg);
    VaoBuffer.shd.set2Float("position", @constCast(&[_]f32{ cell_x - 80, cell_y + 50 }));
    //VaoBuffer.shd.setUint("texId", @intCast(ascii_ch));
    _ = ascii_ch;
    //VaoBuffer.shd.setFloat("fontSize", font_size);
    _ = font_size;
    c.glBindVertexArray(VaoBuffer.vao);
    c.glDrawElements(c.GL_TRIANGLES, 6, c.GL_UNSIGNED_INT, null);
}

/// Draws a simple sprite at a given location. The cells are on a 80x50 grid.
pub fn drawSprite(cell_x: f32, cell_y: f32, fg: Color, bg: Color, ascii_ch: u8) void {
    VaoBuffer.shd.setColor("fg", fg);
    VaoBuffer.shd.setColor("bg", bg);
    VaoBuffer.shd.set2Float("position", @constCast(&[_]f32{ cell_x, -cell_y }));
    VaoBuffer.shd.setFloat("texId", @floatFromInt(ascii_ch));
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
    drawSprite(x_min, y_min, fg, bg, 218);
    drawSprite(x_max, y_max, fg, bg, 217);
    drawSprite(x_min, y_max, fg, bg, 192);
    drawSprite(x_max, y_min, fg, bg, 191);
}

pub fn drawSprite3d(
    cell_x: i32,
    cell_y: i32,
    cell_z: i32,
    fg: Color,
    bg: Color,
    ascii_ch: u8,
) !void {
    _ = cell_z; // autofix
    const ascii_tex_pos_x = ascii_ch % 16;
    const ascii_tex_pos_y = ascii_ch / 16;

    const x = @as(f32, @floatFromInt(ascii_tex_pos_x));
    const y = 15 - @as(f32, @floatFromInt(ascii_tex_pos_y));
    const pos_x = 0.025 * cell_x - 10;
    const pos_y = 0.04 * (-cell_y) - 10;
    const tex_x_offset = 1.0 / 16.0;
    const tex_y_offset = 1.0 / 16.0;
    const cell_size_x = 1.0 / 80.0;
    const cell_size_y = 1.0 / 50.0;

    const vertices = [_][11]f32{
        [_]f32{
            // position
            cell_size_x * 1.0 + pos_x - (1 - cell_size_x),
            0.0,
            cell_size_y * 1.0 + pos_y + (1 - cell_size_y),
            // fg
            fg.r,
            fg.g,
            fg.b,
            // bg
            bg.r,
            bg.g,
            bg.b,
            // texcoord
            tex_x_offset * (x + 1),
            1.0 - tex_y_offset * (y + 1),
        },
        [_]f32{
            // position
            cell_size_x * 1.0 + pos_x - (1 - cell_size_x),
            0.0,
            cell_size_y * -1.0 + pos_y + (1 - cell_size_y),
            // fg
            fg.r,
            fg.g,
            fg.b,
            // bg
            bg.r,
            bg.g,
            bg.b,
            // texcoord
            tex_x_offset * (x + 1),
            1.0 - tex_y_offset * y,
        },
        [_]f32{
            // position
            cell_size_x * -1.0 + pos_x - (1 - cell_size_x),
            0.0,
            cell_size_y * -1.0 + pos_y + (1 - cell_size_y),
            // fg
            fg.r,
            fg.g,
            fg.b,
            // bg
            bg.r,
            bg.g,
            bg.b,
            // texcoord
            tex_x_offset * x,
            1.0 - tex_y_offset * y,
        },
        [_]f32{
            // position
            cell_size_x * -1.0 + pos_x - (1 - cell_size_x),
            0.0,
            cell_size_y * 1.0 + pos_y + (1 - cell_size_y),
            // fg
            fg.r,
            fg.g,
            fg.b,
            // bg
            bg.r,
            bg.g,
            bg.b,
            // texcoord
            tex_x_offset * x,
            1.0 - tex_y_offset * (y + 1),
        },
    };
    var buff = makeVao(vertices);
    c.glBindVertexArray(@intCast(buff.vao));
    c.glDrawElements(c.GL_TRIANGLES, 6, c.GL_UNSIGNED_INT, null);
    buff.deinit();
    c.glBindVertexArray(0);
}

/// Prints a string to the screen. It starts at the given cell_position, and will
/// wrap around to the next row.
pub fn print(cell_x: f32, cell_y: f32, fg: Color, bg: Color, string: []const u8) void {
    var x_position = cell_x;
    for (string) |char| {
        drawSprite(x_position, cell_y, fg, bg, char);
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
        drawSpriteC(x_position, cell_y, fg, bg, char, font_size);
        x_position += 1 * font_size;
    }
}
