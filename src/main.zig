const std = @import("std");
const arena = std.heap.ArenaAllocator;
const app = @import("zRogue.zig");
const run = app.run;
const sh = @import("spritesheet.zig");

fn init() void {}

fn tick() void {
    std.debug.print("Stuff from main\n", .{});
    sh.drawSprite(
        20,
        40,
        .{ .r = 1.0, .g = 0.1, .b = 1.0 },
        .{ .r = 0.0, .g = 0.0, .b = 0.0 },
        'g',
    );
}

pub fn main() !void {
    try run(.{
        .title = "test",
        .init = init,
        .tick = tick,
    });
}
