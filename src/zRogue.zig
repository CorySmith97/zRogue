///
/// ███████╗██████╗  ██████╗  ██████╗ ██╗   ██╗███████╗
/// ╚══███╔╝██╔══██╗██╔═══██╗██╔════╝ ██║   ██║██╔════╝
///   ███╔╝ ██████╔╝██║   ██║██║  ███╗██║   ██║█████╗
///  ███╔╝  ██╔══██╗██║   ██║██║   ██║██║   ██║██╔══╝
/// ███████╗██║  ██║╚██████╔╝╚██████╔╝╚██████╔╝███████╗
/// ╚══════╝╚═╝  ╚═╝ ╚═════╝  ╚═════╝  ╚═════╝ ╚══════╝

// Imports
const std = @import("std");
const c = @cImport({
    @cInclude("stb_image.h");
    @cInclude("SDL2/sdl.h");
    @cInclude("epoxy/gl.h");
});
const zlm = @import("zlm.zig");
const Image = @import("image.zig");
const Shader = @import("Shader.zig");
const w = @import("window.zig");

const math_f32 = zlm.SpecializeOn(f32);

pub const app_desc = struct {
    const Self = @This();
    title: [*c]const u8,
    //allocator: std.heap.ArenaAllocator,
    width: i32 = 80,
    height: i32 = 50,
    tile_width: i32 = 12,
    tile_height: i32 = 12,

    // user defined functions
    init: ?*const fn () void = null,
    tick: ?*const fn () void = null,
    events: ?*const fn () void = null,
};

fn makeVao(points: [4][8]f32) u32 {
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

    c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 8 * @sizeOf(f32), c_offset);
    c.glEnableVertexAttribArray(0);

    const color_offset = @as(?*anyopaque, @ptrFromInt(3 * @sizeOf(f32)));
    c.glVertexAttribPointer(1, 3, c.GL_FLOAT, c.GL_FALSE, 8 * @sizeOf(f32), color_offset);
    c.glEnableVertexAttribArray(1);

    const tex_offset = @as(?*anyopaque, @ptrFromInt(6 * @sizeOf(f32)));
    c.glVertexAttribPointer(2, 2, c.GL_FLOAT, c.GL_FALSE, 8 * @sizeOf(f32), tex_offset);
    c.glEnableVertexAttribArray(2);

    return vao;
}
// This funciton is our app's entry point. We use struct intialization
// in order to help keep this clean.
pub fn run(app: app_desc) !void {
    var img = try Image.init("src/assets/vga8x16.jpg");
    var window = w.init("Test", 800, 600);
    window.createWindow();
    defer window.deinit();

    try window.getGLContext();

    const shd = try Shader.init("src/test.vs", "src/test.fs");

    const vec = math_f32.vec3(1, 1, 1);
    _ = vec;
    const vertices = [_][8]f32{
        [_]f32{ 0.5, 0.5, 0.0, 1.0, 0.0, 1.0, 1.0, 1.0 },
        [_]f32{ 0.5, -0.5, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0 },
        [_]f32{ -0.5, -0.5, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0 },
        [_]f32{ -0.5, 0.5, 0.0, 1.0, 0.0, 0.7, 0.0, 1.0 },
    };
    const texture = try img.imgToTexture();
    img.free();

    const vao = makeVao(vertices);
    if (app.init) |init| {
        init();
    }
    var a: u32 = 0;
    var b: u32 = 0;
    var delta: f64 = 0;

    var quit = false;
    var toggle = false;
    while (!quit) {
        a = c.SDL_GetTicks();
        delta = @as(f64, @floatFromInt(a - b));
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event) != 0) {
            const key = event.key.keysym.sym;
            switch (event.type) {
                c.SDL_QUIT => {
                    quit = true;
                },
                c.SDL_KEYDOWN => {
                    if (key == c.SDLK_h) {
                        toggle = !toggle;
                    }
                    if (key == c.SDLK_ESCAPE) {
                        quit = true;
                    }
                },
                else => {},
            }
        }
        if (toggle) {
            c.glPolygonMode(c.GL_FRONT_AND_BACK, c.GL_LINE);
        } else {
            c.glPolygonMode(c.GL_FRONT_AND_BACK, c.GL_FILL);
        }

        c.glClearColor(0.2, 0.3, 0.3, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT);
        c.glUseProgram(shd.id);
        c.glActiveTexture(c.GL_TEXTURE0);
        c.glBindTexture(c.GL_TEXTURE_2D, texture);

        c.glBindVertexArray(@intCast(vao));
        //c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
        c.glDrawElements(c.GL_TRIANGLES, 6, c.GL_UNSIGNED_INT, null);
        window.swapWindow();
        b = a;
    }
}
