const std = @import("std");
const arena = std.heap.ArenaAllocator;
const app = @import("zRogue.zig");
const run = app.run;
const sh = @import("spritesheet.zig");

fn init() void {}

fn tick() void {
    sh.drawSprite(
        2,
        24,
        sh.GREEN,
        sh.BLACK,
        'g',
    );
    sh.drawSprite(
        4,
        10,
        sh.GREEN,
        sh.WHITE,
        'o',
    );
}

pub fn main() !void {
    try run(.{
        .title = "zRogue",
        .init = init,
        .tick = tick,
    });
}
