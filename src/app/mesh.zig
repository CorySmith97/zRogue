const std = @import("std");
const Shader = @import("shader.zig");
const ArrayList = std.ArrayList;
const Camera = @import("camera.zig");
const Image = @import("image.zig");
const vec3 = Camera.vec3;
const vec2 = Camera.vec2;
const c = @import("c.zig");
const Color = @import("spritesheet.zig").Color;

// 3 f32 for pos
// 3 f32 for norms
// 2 f32 for texture coords
pub const Vertex = [5]f32;

pub const Texture = struct {
    id: u32,
    name: []const u8,
};

pub const MeshType = union(enum) {
    ply: struct {
        path: []const u8,
    },
    cube: struct {
        atlas_id: [3]u8,
        fg_top: Color,
        bg_top: Color,
        fg_sides: Color,
        bg_sides: Color,
        fg_bottom: Color,
        bg_bottom: Color,
    },
};

const Self = @This();
shader: Shader,
vertices: ArrayList(f32),
indices: ArrayList(u16),
textures: ArrayList(Texture),
vao: u32 = std.math.maxInt(u32),
vbo: u32 = std.math.maxInt(u32),
ebo: u32 = std.math.maxInt(u32),

pub fn init(
    self: *Self,
    mtype: MeshType,
    vs_path: []const u8,
    fs_path: []const u8,
    allocator: std.mem.Allocator,
    textures: ArrayList(Texture),
) !void {
    const shd = try Shader.init(vs_path, fs_path);
    switch (mtype) {
        .cube => |*cu| {
            var vertices = std.ArrayList(f32).init(allocator);
            const top_uv = getUVCoords(cu.atlas_id[0]);
            const bottom_uv = getUVCoords(cu.atlas_id[1]);
            const side_uv = getUVCoords(cu.atlas_id[2]);
            const offset = 1.0 / 16.0;
            const fg_sides = cu.fg_sides;
            const fg_top = cu.fg_top;
            const fg_bottom = cu.fg_bottom;
            const bg_sides = cu.bg_sides;
            const bg_top = cu.bg_top;
            const bg_bottom = cu.bg_bottom;

            const vert = [_]f32{
                // Back Face (-Z)
                -0.5, -0.5, 0.5,  0.0,  0.0,  1.0,  fg_sides.r,  fg_sides.g,  fg_sides.b,  bg_sides.r,  bg_sides.g,  bg_sides.b,  offset * (side_uv.u + 1),   1.0 - offset * (side_uv.v + 1),
                0.5,  -0.5, 0.5,  0.0,  0.0,  1.0,  fg_sides.r,  fg_sides.g,  fg_sides.b,  bg_sides.r,  bg_sides.g,  bg_sides.b,  offset * side_uv.u,         1.0 - offset * (side_uv.v + 1),
                0.5,  0.5,  0.5,  0.0,  0.0,  1.0,  fg_sides.r,  fg_sides.g,  fg_sides.b,  bg_sides.r,  bg_sides.g,  bg_sides.b,  offset * side_uv.u,         1.0 - offset * side_uv.v,
                -0.5, 0.5,  0.5,  0.0,  0.0,  1.0,  fg_sides.r,  fg_sides.g,  fg_sides.b,  bg_sides.r,  bg_sides.g,  bg_sides.b,  offset * (side_uv.u + 1),   1.0 - offset * side_uv.v,

                // Back face (negative Z)
                -0.5, -0.5, -0.5, 0.0,  0.0,  -1.0, fg_sides.r,  fg_sides.g,  fg_sides.b,  bg_sides.r,  bg_sides.g,  bg_sides.b,  offset * side_uv.u,         1.0 - offset * (side_uv.v + 1),
                0.5,  -0.5, -0.5, 0.0,  0.0,  -1.0, fg_sides.r,  fg_sides.g,  fg_sides.b,  bg_sides.r,  bg_sides.g,  bg_sides.b,  offset * (side_uv.u + 1),   1.0 - offset * (side_uv.v + 1),
                0.5,  0.5,  -0.5, 0.0,  0.0,  -1.0, fg_sides.r,  fg_sides.g,  fg_sides.b,  bg_sides.r,  bg_sides.g,  bg_sides.b,  offset * (side_uv.u + 1),   1.0 - offset * side_uv.v,
                -0.5, 0.5,  -0.5, 0.0,  0.0,  -1.0, fg_sides.r,  fg_sides.g,  fg_sides.b,  bg_sides.r,  bg_sides.g,  bg_sides.b,  offset * side_uv.u,         1.0 - offset * side_uv.v,

                // Left face (negative X)
                -0.5, -0.5, -0.5, -1.0, 0.0,  0.0,  fg_sides.r,  fg_sides.g,  fg_sides.b,  bg_sides.r,  bg_sides.g,  bg_sides.b,  offset * (side_uv.u + 1),   1.0 - offset * (side_uv.v + 1),
                -0.5, -0.5, 0.5,  -1.0, 0.0,  0.0,  fg_sides.r,  fg_sides.g,  fg_sides.b,  bg_sides.r,  bg_sides.g,  bg_sides.b,  offset * side_uv.u,         1.0 - offset * (side_uv.v + 1),
                -0.5, 0.5,  0.5,  -1.0, 0.0,  0.0,  fg_sides.r,  fg_sides.g,  fg_sides.b,  bg_sides.r,  bg_sides.g,  bg_sides.b,  offset * side_uv.u,         1.0 - offset * side_uv.v,
                -0.5, 0.5,  -0.5, -1.0, 0.0,  0.0,  fg_sides.r,  fg_sides.g,  fg_sides.b,  bg_sides.r,  bg_sides.g,  bg_sides.b,  offset * (side_uv.u + 1),   1.0 - offset * side_uv.v,

                // Right face (positive X)
                0.5,  -0.5, -0.5, 1.0,  0.0,  0.0,  fg_sides.r,  fg_sides.g,  fg_sides.b,  bg_sides.r,  bg_sides.g,  bg_sides.b,  offset * side_uv.u,         1.0 - offset * (side_uv.v + 1),
                0.5,  -0.5, 0.5,  1.0,  0.0,  0.0,  fg_sides.r,  fg_sides.g,  fg_sides.b,  bg_sides.r,  bg_sides.g,  bg_sides.b,  offset * (side_uv.u + 1),   1.0 - offset * (side_uv.v + 1),
                0.5,  0.5,  0.5,  1.0,  0.0,  0.0,  fg_sides.r,  fg_sides.g,  fg_sides.b,  bg_sides.r,  bg_sides.g,  bg_sides.b,  offset * (side_uv.u + 1),   1.0 - offset * side_uv.v,
                0.5,  0.5,  -0.5, 1.0,  0.0,  0.0,  fg_sides.r,  fg_sides.g,  fg_sides.b,  bg_sides.r,  bg_sides.g,  bg_sides.b,  offset * side_uv.u,         1.0 - offset * side_uv.v,

                // Bottom face (negative Y)
                -0.5, -0.5, -0.5, 0.0,  1.0,  0.0,  fg_top.r,    fg_top.g,    fg_top.b,    bg_top.r,    bg_top.g,    bg_top.b,    offset * (top_uv.u + 1),    1.0 - offset * (top_uv.v + 1),
                0.5,  -0.5, -0.5, 0.0,  1.0,  0.0,  fg_top.r,    fg_top.g,    fg_top.b,    bg_top.r,    bg_top.g,    bg_top.b,    offset * top_uv.u,          1.0 - offset * (top_uv.v + 1),
                0.5,  -0.5, 0.5,  0.0,  1.0,  0.0,  fg_top.r,    fg_top.g,    fg_top.b,    bg_top.r,    bg_top.g,    bg_top.b,    offset * top_uv.u,          1.0 - offset * top_uv.v,
                -0.5, -0.5, 0.5,  0.0,  1.0,  0.0,  fg_top.r,    fg_top.g,    fg_top.b,    bg_top.r,    bg_top.g,    bg_top.b,    offset * (top_uv.u + 1),    1.0 - offset * top_uv.v,

                // Top face (positive Y)
                -0.5, 0.5,  -0.5, 0.0,  -1.0, 0.0,  fg_bottom.r, fg_bottom.g, fg_bottom.b, bg_bottom.r, bg_bottom.g, bg_bottom.b, offset * (bottom_uv.u + 1), 1.0 - offset * (bottom_uv.v + 1),
                0.5,  0.5,  -0.5, 0.0,  -1.0, 0.0,  fg_bottom.r, fg_bottom.g, fg_bottom.b, bg_bottom.r, bg_bottom.g, bg_bottom.b, offset * bottom_uv.u,       1.0 - offset * (bottom_uv.v + 1),
                0.5,  0.5,  0.5,  0.0,  -1.0, 0.0,  fg_bottom.r, fg_bottom.g, fg_bottom.b, bg_bottom.r, bg_bottom.g, bg_bottom.b, offset * bottom_uv.u,       1.0 - offset * bottom_uv.v,
                -0.5, 0.5,  0.5,  0.0,  -1.0, 0.0,  fg_bottom.r, fg_bottom.g, fg_bottom.b, bg_bottom.r, bg_bottom.g, bg_bottom.b, offset * (bottom_uv.u + 1), 1.0 - offset * bottom_uv.v,
            };

            try vertices.appendSlice(&vert);
            const inds = [_]u16{
                0, 1, 2, 0, 2, 3, // Front face
                4, 5, 6, 4, 6, 7, // Back face
                8, 9, 10, 8, 10, 11, // Left face
                12, 13, 14, 12, 14, 15, // Right face
                16, 17, 18, 16, 18, 19, // Bottom face
                20, 21, 22, 20, 22,
                23, // Top face
            };
            //
            var indices = std.ArrayList(u16).init(allocator);

            try indices.appendSlice(&inds);

            self.* = .{
                .shader = shd,
                .vertices = vertices,
                .indices = indices,
                .textures = textures,
            };
        },
        else => {},
    }

    try self.setupMesh();
}

pub fn setupMesh(self: *Self) !void {
    var vao: c_uint = undefined;
    c.glGenVertexArrays(1, &vao);
    c.glBindVertexArray(vao);

    var vbo: u32 = 0;
    c.glGenBuffers(1, &vbo);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
    c.glBufferData(
        c.GL_ARRAY_BUFFER,
        @as(c_long, @intCast(self.vertices.items.len * @sizeOf(c.GLfloat))),
        self.vertices.items.ptr,
        c.GL_STATIC_DRAW,
    );
    var ebo: u32 = 0;
    c.glGenBuffers(1, &ebo);
    c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, ebo);
    c.glBufferData(
        c.GL_ELEMENT_ARRAY_BUFFER,
        @as(c_long, @intCast(self.indices.items.len * @sizeOf(u16))),
        self.indices.items.ptr,
        c.GL_STATIC_DRAW,
    );
    const c_offset = @as(?*anyopaque, @ptrFromInt(0));

    c.glVertexAttribPointer(
        0,
        3,
        c.GL_FLOAT,
        c.GL_FALSE,
        14 * @sizeOf(f32),
        c_offset,
    );
    c.glEnableVertexAttribArray(0);

    const norm_offset = @as(?*anyopaque, @ptrFromInt(3 * @sizeOf(f32)));
    c.glVertexAttribPointer(
        1,
        3,
        c.GL_FLOAT,
        c.GL_FALSE,
        14 * @sizeOf(f32),
        norm_offset,
    );
    c.glEnableVertexAttribArray(1);

    const fg_offset = @as(?*anyopaque, @ptrFromInt(6 * @sizeOf(f32)));
    c.glVertexAttribPointer(
        2,
        3,
        c.GL_FLOAT,
        c.GL_FALSE,
        14 * @sizeOf(f32),
        fg_offset,
    );
    c.glEnableVertexAttribArray(2);

    const bg_offset = @as(?*anyopaque, @ptrFromInt(9 * @sizeOf(f32)));
    c.glVertexAttribPointer(
        3,
        3,
        c.GL_FLOAT,
        c.GL_FALSE,
        14 * @sizeOf(f32),
        bg_offset,
    );
    c.glEnableVertexAttribArray(3);
    const tex_offset = @as(?*anyopaque, @ptrFromInt(12 * @sizeOf(f32)));
    c.glVertexAttribPointer(
        4,
        2,
        c.GL_FLOAT,
        c.GL_FALSE,
        14 * @sizeOf(f32),
        tex_offset,
    );
    c.glEnableVertexAttribArray(4);
    c.glBindVertexArray(0);

    self.vao = vao;
    self.vbo = vbo;
    self.ebo = ebo;
}

pub fn draw(self: *Self) void {
    c.glActiveTexture(c.GL_TEXTURE0);
    c.glBindTexture(c.GL_TEXTURE_2D, self.textures.items[0].id);

    c.glBindVertexArray(@intCast(self.vao));
    c.glDrawElementsInstanced(
        c.GL_TRIANGLES,
        @intCast(self.indices.items.len),
        c.GL_UNSIGNED_SHORT,
        null,
        100,
    );
    //c.glDisableVertexAttribArray(0);
    //c.glDisableVertexAttribArray(1);
    //c.glDisableVertexAttribArray(2);
    //c.glDisableVertexAttribArray(3);
    //c.glDisableVertexAttribArray(4);
    c.glBindVertexArray(0);
}

pub fn deinit(self: *Self) void {
    self.indices.deinit();
    self.vertices.deinit();
    self.textures.deinit();
}

const Ply = struct {
    const P = @This();

    vertex: ?ArrayList(f32),
    vertex_count: u32 = 0,

    faces: ?ArrayList(u16),
    faces_count: u32 = 0,

    /// This only loads Geometric Vertices and the faces.
    /// TODO: Add Texture Coords, as well as Unit vectors
    pub fn loadPlyVN(ply_path: []const u8, allocator: std.mem.Allocator) !P {
        const max_file_size = 1_000_000;

        var vertex = ArrayList(f32).init(allocator);
        var vertex_count: u32 = 0;

        var face_vecs = ArrayList(u16).init(allocator);
        var faces_count: u32 = 0;

        var f = try std.fs.cwd().openFile(ply_path, .{});
        errdefer f.close();

        var buf_reader = std.io.bufferedReader(f.reader());
        var in_stream = buf_reader.reader();

        var buf: [max_file_size]u8 = undefined;

        var header_finished = false;
        var vertex_parsed: u32 = 0;
        var face_parsed: u32 = 0;

        while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            if (std.mem.startsWith(u8, line, "element vertex")) {
                var line_split = std.mem.split(u8, line, " ");
                while (line_split.next()) |items| {
                    if (std.mem.eql(u8, items, "element")) {
                        continue;
                    }
                    if (std.mem.eql(u8, items, "vertex")) {
                        continue;
                    }
                    std.debug.print("Line: {s}\n", .{items});
                    const parsed = try std.fmt.parseInt(u32, items, 10);

                    vertex_count = parsed;
                }
            }
            if (std.mem.startsWith(u8, line, "element face")) {
                var line_split = std.mem.split(u8, line, " ");
                while (line_split.next()) |items| {
                    if (std.mem.eql(u8, items, "element")) {
                        continue;
                    }
                    if (std.mem.eql(u8, items, "face")) {
                        continue;
                    }
                    const parsed = try std.fmt.parseInt(u32, items, 10);

                    faces_count = parsed;
                }
            }
            if (std.mem.startsWith(u8, line, "end_header")) {
                header_finished = true;
                continue;
            }
            if (header_finished) {
                if (vertex_parsed < vertex_count * 6) {
                    var line_split = std.mem.split(u8, line, " ");
                    var parse: u32 = 0;
                    while (line_split.next()) |items| {
                        const parsed = try std.fmt.parseFloat(f32, items);

                        try vertex.append(parsed);
                        vertex_parsed += 1;
                        parse += 1;
                        if (parse >= 6) {
                            break;
                        }
                    }
                } else if (face_parsed < faces_count * 3) {
                    var line_split = std.mem.split(u8, line, " ");
                    _ = line_split.next();
                    while (line_split.next()) |items| {
                        const face = try std.fmt.parseInt(u16, items, 10);
                        try face_vecs.append(face);
                        face_parsed += 1;
                    }
                }
            } else {
                continue;
            }
        }

        return P{
            .vertex = vertex,
            .vertex_count = vertex_count,
            .faces = face_vecs,
            .faces_count = faces_count,
        };
    }
};

const UV = struct {
    u: f32,
    v: f32,
};

pub fn getUVCoords(index: u8) UV {
    const ascii_sprite_x = @as(f32, @floatFromInt(index % 16));
    const ascii_sprite_y = @as(f32, @floatFromInt(index / 16));

    const u = ascii_sprite_x - 0.05;
    const v = 15 - ascii_sprite_y;
    return UV{
        .u = u,
        .v = v,
    };
}
