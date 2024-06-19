///
/// ███████╗██████╗  ██████╗  ██████╗ ██╗   ██╗███████╗
/// ╚══███╔╝██╔══██╗██╔═══██╗██╔════╝ ██║   ██║██╔════╝
///   ███╔╝ ██████╔╝██║   ██║██║  ███╗██║   ██║█████╗
///  ███╔╝  ██╔══██╗██║   ██║██║   ██║██║   ██║██╔══╝
/// ███████╗██║  ██║╚██████╔╝╚██████╔╝╚██████╔╝███████╗
/// ╚══════╝╚═╝  ╚═╝ ╚═════╝  ╚═════╝  ╚═════╝ ╚══════╝

// Imports
const std = @import("std");
const log = std.log;
const c = @import("c.zig");
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
    target_fps: i32 = 60,

    // user defined functions
    init: ?*const fn () void = null,
    tick: ?*const fn () void = null,
    events: ?*const fn (event: c.SDL_Event, quit: *bool) void = null,
};

const KEYTYPE = c.SDL_Event.key.keysym.sym;
const KEY_A = c.SDLK_a;

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
    log.info("[LOG] LibEpoxy Version: {}\n", .{c.epoxy_gl_version()});
    var a: u32 = 0;
    var b: u32 = 0;
    var delta: f64 = 0;

    var quit = false;
    while (!quit) {
        a = c.SDL_GetTicks();
        delta = @as(f64, @floatFromInt(a - b));
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event) != 0) {
            if (app.events) |events| {
                events(event, &quit);
            }
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
