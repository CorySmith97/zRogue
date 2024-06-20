const std = @import("std");
const app = @import("zRogue.zig");
const run = app.run;
const s = @import("spritesheet.zig");
const c = @import("c.zig");

const TileTypes = enum {
    Wall,
    Floor,
};

const Player = struct {
    fg: s.Color,
    bg: s.Color,
    char: u8,
    x: f32,
    y: f32,
};

const State = struct {
    player: Player,
    allocator: std.mem.Allocator,
    map: std.ArrayList(TileTypes),
};

var state: State = undefined;

fn init() void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        _ = gpa.deinit();
    }
    state = .{
        .player = .{
            .fg = s.DARK_BLUE,
            .bg = s.BLACK,
            .char = '@',
            .x = 10,
            .y = 5,
        },
        .allocator = gpa.allocator(),
        .map = std.ArrayList(TileTypes).init(gpa.allocator()),
    };
}

fn tick() void {
    s.drawSprite(4, 10, s.TEAL, s.BLACK, '1');
    s.drawSprite(5, 10, s.MAGENTA, s.BLACK, '2');
    s.drawSprite(6, 10, s.MUSTARD, s.BLACK, '3');
    s.drawSprite(7, 10, s.DARK_BLUE, s.BLACK, '4');
    s.drawSprite(8, 10, s.PASTEL_RED, s.BLACK, '5');
    s.drawSprite(9, 10, s.PASTEL_PINK, s.BLACK, '6');
    s.drawSprite(10, 10, s.PASTEL_BLUE, s.BLACK, '7');
    s.drawSprite(11, 10, s.PASTEL_ORANGE, s.BLACK, '8');
    // letters test

    s.drawSprite(4, 11, s.TEAL, s.BLACK, 'a');
    s.drawSprite(5, 11, s.MAGENTA, s.BLACK, 'b');
    s.drawSprite(6, 11, s.MUSTARD, s.BLACK, 'c');
    s.drawSprite(7, 11, s.DARK_BLUE, s.BLACK, 'd');
    s.drawSprite(8, 11, s.PASTEL_RED, s.BLACK, 'e');
    s.drawSprite(9, 11, s.PASTEL_PINK, s.BLACK, 'f');
    s.drawSprite(10, 11, s.PASTEL_BLUE, s.BLACK, 'g');
    s.drawSprite(11, 11, s.PASTEL_ORANGE, s.BLACK, 'h');
    s.drawSprite(12, 11, s.PASTEL_ORANGE, s.BLACK, 2);
    s.drawSprite(35, 11, s.PASTEL_ORANGE, s.BLACK, 2);
    s.drawSprite(
        state.player.x,
        state.player.y,
        state.player.fg,
        state.player.bg,
        state.player.char,
    );
}

pub fn input(event: *app.Event) void {
    if (event.isKeyDown(app.KEY_A)) {
        state.player.x -= 1;
    }
    if (event.isKeyDown(app.KEY_D)) {
        state.player.x += 1;
    }
    if (event.isKeyDown(app.KEY_W)) {
        state.player.y -= 1;
    }
    if (event.isKeyDown(app.KEY_S)) {
        state.player.y += 1;
    }
    if (event.isKeyDown(app.KEY_Escape)) {
        event.windowShouldClose(true);
    }
}

pub fn main() !void {
    try run(.{
        .title = "zRogue",
        .init = init,
        .tick = tick,
        .events = input,
    });
}
