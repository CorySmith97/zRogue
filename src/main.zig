const std = @import("std");
const c = @cImport(@cInclude("SDL2/sdl.h"));
const app = @import("lib/app.zig");

fn init() void {
    std.debug.print("hello\n", .{});
}

fn tick(ren: *c.SDL_Renderer) void {
    _ = c.SDL_RenderClear(ren);
    _ = c.SDL_SetRenderDrawColor(
        ren,
        255,
        100,
        255,
        255,
    );
    _ = c.SDL_RenderPresent(ren);
}

pub fn main() !void {
    app.run(.{
        .title = "test",
        .init = init,
        .tick = tick,
    });
}
