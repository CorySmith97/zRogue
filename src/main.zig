const std = @import("std");
const arena = std.heap.ArenaAllocator;
const app = @import("zRogue.zig");
const run = app.run;
const sh = @import("spritesheet.zig");

fn init() void {}

fn tick() void {
    std.debug.print("Stuff from main\n", .{});
    sh.drawSprite(
        2,
        10,
        sh.GREEN,
        sh.BLACK,
        'g',
    );
}

pub fn main() !void {
    try run(.{
        .title = "BIG BOOTY",
        .init = init,
        .tick = tick,
    });
}
