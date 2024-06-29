const std = @import("std");
const app = @import("zRogue");
const run = app.run;
const s = app.Sprite;

/// map.zig
const TileTypes = enum {
    Wall,
    Floor,
};

pub fn index(x: f32, y: f32) usize {
    const idx = @as(usize, @intFromFloat((y * 80) + x));
    return idx;
}

pub fn newMap() ![80 * 50]TileTypes {
    var map = [_]TileTypes{TileTypes.Floor} ** (80 * 50);

    var x: f32 = 0;
    while (x < 80) : (x += 1) {
        map[index(x, 0)] = TileTypes.Wall;
        map[index(x, 49)] = TileTypes.Wall;
    }
    var y: f32 = 0;
    while (y < 50) : (y += 1) {
        map[index(0, y)] = TileTypes.Wall;
        map[index(79, y)] = TileTypes.Wall;
    }

    const rand = app.rng.random();

    var i: f32 = 0;
    while (i < 400) : (i += 1) {
        const rand_x = rand.float(f32) * 79.0;
        const rand_y = rand.float(f32) * 49.0;
        const rand_idx = index(rand_x, rand_y);
        if (rand_idx != index(40, 25)) {
            map[rand_idx] = TileTypes.Wall;
        }
    }

    return map;
}
/// end map.zig
const Player = struct {
    fg: s.Color,
    bg: s.Color,
    char: u8,
    x: f32,
    y: f32,
};

const State = struct {
    const Self = @This();
    player: Player,
    allocator: std.mem.Allocator,
    map: [80 * 50]TileTypes,

    pub fn drawMap(self: *Self) void {
        var x: f32 = 0;
        var y: f32 = 0;

        for (self.map) |cell| {
            //std.debug.print("{any}\n", .{cell});
            switch (cell) {
                TileTypes.Wall => s.drawSprite(x, y, s.GREEN, s.BLACK, '#'),
                TileTypes.Floor => s.drawSprite(x, y, s.PASTEL_PINK, s.BLACK, '.'),
            }
            x += 1;
            if (x >= 80) {
                x = 0;
                y += 1;
            }
        }
    }
};

var state: State = undefined;

fn init() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        _ = gpa.deinit();
    }
    state = .{
        .player = .{
            .fg = s.YELLOW,
            .bg = s.BLACK,
            .char = '@',
            .x = 10,
            .y = 5,
        },
        .allocator = gpa.allocator(),
        .map = try newMap(),
    };
}

fn tick() !void {
    state.drawMap();
    s.drawSprite(
        state.player.x,
        state.player.y,
        state.player.fg,
        state.player.bg,
        state.player.char,
    );
}

pub fn input(event: *app.Event) !void {
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
