const std = @import("std");
const c = @cImport(@cInclude("SDL2/sdl.h"));
const app = @import("lib/app.zig");

pub fn init() void {
    std.debug.print("hello\n", .{});
}

pub fn tick(ren: *c.SDL_Renderer) void {
    _ = c.SDL_RenderClear(ren);
    _ = c.SDL_SetRenderDrawColor(
        ren,
        255,
        100,
        255,
        255,
    );
    std.debug.print("[LOG] FRAME\n", .{});
}

pub fn main() !void {
    app.run(.{
        .title = "test",
        .init = init,
        .tick = tick,
    });
}
