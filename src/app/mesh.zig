const std = @import("std");
const Shader = @import("shader.zig");
const ArrayList = std.ArrayList;
const Camera = @import("camera.zig");
const vec3 = Camera.vec3;
const vec2 = Camera.vec2;
const c = @import("c.zig");

// 3 f32 for pos
// 3 f32 for norms
// 2 f32 for texture coords
pub const Vertex = [5]f32;

pub const Texture = struct {
    id: u32,
    name: []const u8,
};

const Self = @This();
vertices: ArrayList(f32),
indices: ArrayList(u16),
textures: ArrayList(Texture),
vao: u32 = std.math.maxInt(u32),
vbo: u32 = std.math.maxInt(u32),
ebo: u32 = std.math.maxInt(u32),

pub fn init(
    self: *Self,
    vertices: ArrayList(f32),
    indices: ArrayList(u16),
    textures: ArrayList(Texture),
) !void {
    self.* = .{
        .vertices = vertices,
        .indices = indices,
        .textures = textures,
    };

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
        8 * @sizeOf(f32),
        c_offset,
    );
    c.glEnableVertexAttribArray(0);

    const norm_offset = @as(?*anyopaque, @ptrFromInt(3 * @sizeOf(f32)));
    c.glVertexAttribPointer(
        1,
        3,
        c.GL_FLOAT,
        c.GL_FALSE,
        8 * @sizeOf(f32),
        norm_offset,
    );
    c.glEnableVertexAttribArray(1);

    const tex_offset = @as(?*anyopaque, @ptrFromInt(6 * @sizeOf(f32)));
    c.glVertexAttribPointer(
        2,
        2,
        c.GL_FLOAT,
        c.GL_FALSE,
        8 * @sizeOf(f32),
        tex_offset,
    );
    c.glEnableVertexAttribArray(2);
    c.glBindVertexArray(0);

    self.vao = vao;
    self.vbo = vbo;
    self.ebo = ebo;
}

pub fn draw(self: *Self) void {
    c.glActiveTexture(c.GL_TEXTURE0);
    c.glBindTexture(c.GL_TEXTURE_2D, self.textures.items[0].id);

    c.glBindVertexArray(@intCast(self.vao));
    c.glDrawElements(c.GL_TRIANGLES, @intCast(self.indices.items.len), c.GL_UNSIGNED_SHORT, null);
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
