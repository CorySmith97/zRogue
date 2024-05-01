// Imports
const std = @import("std");
const c = @cImport(@cInclude("SDL2/sdl.h"));

pub const app_desc = struct {
    const Self = @This();
    title: [*c]const u8,
    width: i32 = 80,
    height: i32 = 50,
    tile_width: i32 = 8,
    tile_height: i32 = 8,
    delta: f64 = 0.0,

    // user defined functions
    init: ?*const fn () void = null,
    tick: ?*const fn (renderer: *c.SDL_Renderer) void = null,
    events: ?*const fn () void = null,
};

// This funciton is our app's entry point. We use struct intialization
// in order to help keep this clean.
pub fn run(app: app_desc) void {
    if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
        std.debug.print("ERROR in intialization: {s}\n", .{c.SDL_GetError()});
        return;
    }
    const window = c.SDL_CreateWindow(
        app.title,
        100,
        100,
        app.width * app.tile_width,
        app.height * app.tile_height,
        0,
    );
    defer c.SDL_DestroyWindow(window);

    const renderer = c.SDL_CreateRenderer(
        window,
        0,
        c.SDL_RENDERER_ACCELERATED,
    );
    defer c.SDL_DestroyRenderer(renderer);

    if (app.init) |init| {
        init();
    }
    var a: u32 = 0;
    var b: u32 = 0;
    var delta: f64 = 0;

    var quit = false;
    while (!quit) {
        a = c.SDL_GetTicks();
        delta = @as(f64, @floatFromInt(a - b));
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                c.SDL_QUIT => {
                    quit = true;
                },
                else => {},
            }
        }
        if (delta > @divTrunc(1000.0, 60.0)) {
            if (app.tick) |tick| {
                if (renderer) |ren| {
                    tick(ren);
                }
            }
        }
        b = a;
    }
}
