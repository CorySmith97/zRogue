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

const Vec2 = struct {
    x: f32,
    y: f32,
};

pub const Rect = struct {
    const Self = @This();
    x: f32,
    y: f32,
    x2: f32,
    y2: f32,

    pub fn new(x: f32, y: f32, width: f32, height: f32) Self {
        return Self{
            .x = x,
            .y = y,
            .x2 = x + width,
            .y2 = y + height,
        };
    }

    pub fn intersects(self: *Self, other: Rect) bool {
        if ((self.x <= other.x2) and (self.x2 >= other.x) and (self.y <= other.y2) and (self.y2 >= other.y)) {
            return true;
        } else {
            return false;
        }
    }

    pub fn center(self: *Self) Vec2 {
        return .{
            .x = (self.x + self.x2) / 2,
            .y = (self.y + self.y2) / 2,
        };
    }

    pub fn applyRoomToMap(self: *Self, map: *[80 * 50]TileTypes) void {
        for (@as(usize, @intFromFloat(self.y + 1))..@as(usize, @intFromFloat(self.y2))) |y| {
            std.debug.print("Room y: {}\n", .{y});
            for (@as(usize, @intFromFloat(self.x + 1))..@as(usize, @intFromFloat(self.x2))) |x| {
                map.*[index(@as(f32, @floatFromInt(x)), @as(f32, @floatFromInt(y)))] = TileTypes.Floor;
            }
        }
        std.debug.print("Room\n", .{});
    }
};

pub fn newMapWithRooms() ![80 * 50]TileTypes {
    var map = [_]TileTypes{TileTypes.Wall} ** (80 * 50);

    var room = Rect.new(20, 15, 10, 15);

    room.applyRoomToMap(&map);

    return map;
}

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
        .map = try newMapWithRooms(),
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
