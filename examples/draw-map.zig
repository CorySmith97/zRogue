const std = @import("std");
const ArrayList = std.ArrayList;
const app = @import("zRogue");
const s = app.Sprite;

const TileTypes = enum { Wall, Floor };
const Player = struct {
    x: f32,
    y: f32,
    foreground_color: s.Color,
    background_color: s.Color,
    sprite: u8,
};
pub const State = struct {
    player: Player,
    allocator: std.mem.Allocator,
    map: std.ArrayList(TileTypes),
};
pub fn index(x: f32, y: f32) usize {
    const idx = @as(usize, @intFromFloat((y * 80) + x));
    return idx;
}

pub fn newMap() !std.ArrayList(TileTypes) {
    var map = try std.ArrayList(TileTypes).initCapacity(std.heap.page_allocator, 80 * 50);

    for (0..(80 * 50)) |i| {
        try map.insert(i, TileTypes.Floor);
    }

    var x: f32 = 0;
    while (x < 80) : (x += 1) {
        map.items[index(x, 0)] = TileTypes.Wall;
        map.items[index(x, 49)] = TileTypes.Wall;
    }
    var y: f32 = 0;
    while (y < 50) : (y += 1) {
        map.items[index(0, y)] = TileTypes.Wall;
        map.items[index(79, y)] = TileTypes.Wall;
    }

    const rand = app.rng.random();

    var i: f32 = 0;
    while (i < 400) : (i += 1) {
        const rand_x = rand.float(f32) * 79.0;
        const rand_y = rand.float(f32) * 49.0;
        const rand_idx = index(rand_x, rand_y);
        if (rand_idx != index(40, 25)) {
            map.items[rand_idx] = TileTypes.Wall;
        }
    }

    return map;
}

var state: State = undefined;
var gpa: std.heap.GeneralPurposeAllocator(.{}) = undefined;

pub fn init() !void {
    gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    state = .{
        .player = .{
            .x = 10,
            .y = 10,
            .foreground_color = s.TEAL,
            .background_color = s.BLACK,
            .sprite = '@',
        },
        .allocator = allocator,
        .map = try newMap(),
    };
}

pub fn tick() !void {
    var x: f32 = 0;
    var y: f32 = 0;
    for (state.map.items) |cell| {
        switch (cell) {
            TileTypes.Wall => s.drawSprite(x, y, s.GREEN, s.BLACK, '#'),
            TileTypes.Floor => s.drawSprite(x, y, s.WHITE, s.BLACK, '.'),
        }
        x += 1;
        if (x >= 80) {
            x = 0;
            y += 1;
        }
    }

    s.drawSprite(state.player.x, state.player.y, state.player.foreground_color, state.player.background_color, state.player.sprite);
}
pub fn events(event: *app.Event) !void {
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
}
pub fn cleanup() !void {
    state.map.deinit();
    _ = gpa.deinit();
}

pub fn main() !void {
    try app.run(.{
        .init = init,
        .tick = tick,
        .events = events,
        .cleanup = cleanup,
        .title = "Draw a Map",
    });
}
