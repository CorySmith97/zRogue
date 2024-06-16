const std = @import("std");
const c = @import("c.zig");

pub const Color = struct {
    r: f32,
    g: f32,
    b: f32,
};

pub const WHITE = Color{ .r = 1.0, .g = 1.0, .b = 1.0 };
pub const BLACK = Color{ .r = 0.0, .g = 0.0, .b = 0.0 };
pub const GREEN = Color{ .r = 0.0, .g = 1.0, .b = 0.0 };

fn makeVao(points: [4][10]f32) u32 {
    const indices = [_][3]u32{
        [_]u32{ 0, 1, 2 },
        [_]u32{ 0, 2, 3 },
    };
    var vao: c_uint = undefined;
    c.glGenVertexArrays(1, &vao);
    c.glBindVertexArray(vao);

    var vbo: u32 = 0;
    c.glGenBuffers(1, &vbo);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
    c.glBufferData(c.GL_ARRAY_BUFFER, points.len * points[0].len * @sizeOf(c.GLfloat), &points, c.GL_STATIC_DRAW);
    var ebo: u32 = 0;
    c.glGenBuffers(1, &ebo);
    c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, ebo);
    c.glBufferData(c.GL_ELEMENT_ARRAY_BUFFER, 6 * @sizeOf(u32), &indices, c.GL_STATIC_DRAW);
    const c_offset = @as(?*anyopaque, @ptrFromInt(0));

    c.glVertexAttribPointer(0, 2, c.GL_FLOAT, c.GL_FALSE, 10 * @sizeOf(f32), c_offset);
    c.glEnableVertexAttribArray(0);

    const fg_offset = @as(?*anyopaque, @ptrFromInt(2 * @sizeOf(f32)));
    c.glVertexAttribPointer(1, 3, c.GL_FLOAT, c.GL_FALSE, 10 * @sizeOf(f32), fg_offset);
    c.glEnableVertexAttribArray(1);

    const bg_offset = @as(?*anyopaque, @ptrFromInt(5 * @sizeOf(f32)));
    c.glVertexAttribPointer(2, 3, c.GL_FLOAT, c.GL_FALSE, 10 * @sizeOf(f32), bg_offset);
    c.glEnableVertexAttribArray(2);

    const tex_offset = @as(?*anyopaque, @ptrFromInt(8 * @sizeOf(f32)));
    c.glVertexAttribPointer(3, 2, c.GL_FLOAT, c.GL_FALSE, 10 * @sizeOf(f32), tex_offset);
    c.glEnableVertexAttribArray(3);

    return vao;
}

const Self = @This();
sprite_width: i32,
sprite_height: i32,
tex_width: i32,
tex_height: i32,
tex: i32,

pub fn init(t: i32, tW: i32, tH: i32, sW: i32, sH: i32) Self {
    return .{
        .sprite_width = sW,
        .sprite_height = sH,
        .tex_width = tW,
        .tex_height = tH,
        .tex = t,
    };
}

pub fn drawSprite(cell_x: f32, cell_y: f32, fg: Color, bg: Color, ascii_ch: u8) void {
    const ascii_tex_pos_x = ascii_ch % 16 + 1;
    const ascii_tex_pos_y = ascii_ch / 16;

    const x = 15 - @as(f32, @floatFromInt(ascii_tex_pos_x));
    const y = 15 - @as(f32, @floatFromInt(ascii_tex_pos_y));
    const pos_x = 0.05 * cell_x;
    const pos_y = 0.08 * (-cell_y);
    const vertices = [_][10]f32{
        [_]f32{
            // position
            0.025 * 1.0 + pos_x - 0.975,
            0.04 * 1.0 + pos_y + 0.96,
            // fg
            fg.r,
            fg.g,
            fg.b,
            // bg
            bg.r,
            bg.g,
            bg.b,
            // texcoord
            0.0625 + 0.0625 * x,
            0.0625 + 0.0625 * y,
        },
        [_]f32{
            // position
            0.025 * 1.0 + pos_x - 0.975,
            0.04 * -1.0 + pos_y + 0.96,
            // fg
            fg.r,
            fg.g,
            fg.b,
            // bg
            bg.r,
            bg.g,
            bg.b,
            // texcoord
            0.0625 + 0.0625 * x,
            0.0 + 0.0625 * y,
        },
        [_]f32{
            // position
            0.025 * -1.0 + pos_x - 0.975,
            0.04 * -1.0 + pos_y + 0.96,
            // fg
            fg.r,
            fg.g,
            fg.b,
            // bg
            bg.r,
            bg.g,
            bg.b,
            // texcoord
            0.0 + 0.0625 * x,
            0.0 + 0.0625 * y,
        },
        [_]f32{
            // position
            0.025 * -1.0 + pos_x - 0.975,
            0.04 * 1.0 + pos_y + 0.96,
            // fg
            fg.r,
            fg.g,
            fg.b,
            // bg
            bg.r,
            bg.g,
            bg.b,
            // texcoord
            0.0 + 0.0625 * x,
            0.0625 + 0.0625 * y,
        },
    };
    const vao = makeVao(vertices);
    c.glBindVertexArray(@intCast(vao));
    c.glDrawElements(c.GL_TRIANGLES, 6, c.GL_UNSIGNED_INT, null);
}
