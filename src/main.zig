const std = @import("std");
const arena = std.heap.ArenaAllocator;
const c = @cImport(@cInclude("SDL2/sdl.h"));
const app = @import("zRogue.zig");
const run = app.run;

fn init() void {}

fn tick() void {}

pub fn main() !void {
    try run(.{
        .title = "test",
        .init = init,
        .tick = tick,
    });
}
