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
    @cInclude("SDL2/SDL.h");
    @cInclude("epoxy/gl.h");
});
const Image = @import("image.zig");
const Shader = @import("Shader.zig");
const w = @import("window.zig");
const sh = @import("spritesheet.zig");

pub const AppDesc = struct {
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

// This funciton is our app's entry point. We use struct intialization
// in order to help keep this clean.
pub fn run(app: AppDesc) !void {
    var img = try Image.init("src/assets/vga8x16.jpg");
    var window = w.init(app.title, 800, 600);
    window.createWindow();
    defer window.deinit();

    try window.getGLContext();

    const shd = try Shader.init("src/test.vs", "src/test.fs");
    const texture = try img.imgToTexture();
    img.free();

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

        window.drawBackgroundColor(0.0, 0.0, 0.0);
        c.glUseProgram(shd.id);
        c.glActiveTexture(c.GL_TEXTURE0);
        c.glBindTexture(c.GL_TEXTURE_2D, texture);

        if (app.tick) |tick| {
            tick();
        }

        //c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
        window.swapWindow();
        b = a;
    }
}
