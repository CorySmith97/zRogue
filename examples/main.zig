const std = @import("std");
const app = @import("zRogue");
const run = app.run;
const s = app.Sprite;

/// map.zig
const TileTypes = enum {
    Wall,
    Floor,
};

pub fn i32tof32(x: i32) f32 {
    return @as(f32, @floatFromInt(x));
}
pub fn usizetof32(x: usize) f32 {
    return @as(f32, @floatFromInt(x));
}

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
    const Self = @This();
    fg: s.Color,
    bg: s.Color,
    char: u8,
    pos: Vec2,
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
    pub fn tryToMove(self: *Self, delta_x: f32, delta_y: f32) void {
        const destination_idx = index(self.player.pos.x + delta_x, self.player.pos.y + delta_y);
        if (self.map[destination_idx] != TileTypes.Wall) {
            self.player.pos.x = @min(79, @max(0, self.player.pos.x + delta_x));
            self.player.pos.y = @min(49, @max(0, self.player.pos.y + delta_y));
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

    pub fn intersects(self: *const Self, other: Rect) bool {
        if ((self.x <= other.x2) and (self.x2 >= other.x) and (self.y <= other.y2) and (self.y2 >= other.y)) {
            return true;
        } else {
            return false;
        }
    }

    pub fn center(self: *const Self) Vec2 {
        return .{
            .x = std.math.floor((self.x + self.x2) / 2),
            .y = std.math.floor((self.y + self.y2) / 2),
        };
    }

    pub fn applyRoomToMap(self: *const Self, map: *[80 * 50]TileTypes) void {
        for (@as(usize, @intFromFloat(self.y + 1))..@as(usize, @intFromFloat(self.y2))) |y| {
            for (@as(usize, @intFromFloat(self.x + 1))..@as(usize, @intFromFloat(self.x2))) |x| {
                map.*[index(usizetof32(x), usizetof32(y))] = TileTypes.Floor;
            }
        }
        std.debug.print("Room\n", .{});
    }
};

pub fn horizontal_tunnel(map: *[80 * 50]TileTypes, x1: f32, x2: f32, y: f32) void {
    for (@as(usize, @intFromFloat(@min(x1, x2)))..(@as(usize, @intFromFloat(@max(x1, x2))) + 1)) |x| {
        const idx = index(usizetof32(x), y);
        if (0 < idx and idx < (80 * 50)) {
            map.*[idx] = TileTypes.Floor;
        }
    }
}
pub fn vertical_tunnel(map: *[80 * 50]TileTypes, y1: f32, y2: f32, x: f32) void {
    for (@as(usize, @intFromFloat(@min(y1, y2)))..(@as(usize, @intFromFloat(@max(y1, y2))) + 1)) |y| {
        const idx = index(x, usizetof32(y));
        if (0 < idx and idx < (80 * 50)) {
            map.*[idx] = TileTypes.Floor;
        }
    }
}

pub fn newMapWithRooms() ![80 * 50]TileTypes {
    var map = [_]TileTypes{TileTypes.Wall} ** (80 * 50);
    var rooms = std.ArrayList(Rect).init(state.allocator);
    defer rooms.deinit();

    const MAX_ROOMS = 30;
    const MIN_SIZE = 6;
    const MAX_SIZE = 10;
    var rand = app.rng.random();

    for (0..MAX_ROOMS) |_| {
        const w = rand.intRangeAtMost(i32, MIN_SIZE, MAX_SIZE);
        const h = rand.intRangeAtMost(i32, MIN_SIZE, MAX_SIZE);
        const x = rand.intRangeAtMost(i32, 1, 80 - w - 1) - 1;
        const y = rand.intRangeAtMost(i32, 1, 50 - h - 1) - 1;
        const new_room = Rect.new(
            i32tof32(x),
            i32tof32(y),
            i32tof32(w),
            i32tof32(h),
        );
        var new_room_ok = true;
        for (rooms.items) |room| {
            if (room.intersects(new_room)) {
                new_room_ok = false;
            }
        }
        if (new_room_ok) {
            new_room.applyRoomToMap(&map);
            if (rooms.items.len != 0) {
                const new = new_room.center();
                const prev = rooms.items[rooms.items.len - 1].center();

                if (rand.intRangeAtMost(i32, 0, 2) == 1) {
                    horizontal_tunnel(&map, prev.x, new.x, prev.y);
                    vertical_tunnel(&map, prev.y, new.y, new.x);
                } else {
                    horizontal_tunnel(&map, prev.x, new.x, new.y);
                    vertical_tunnel(&map, prev.y, new.y, prev.x);
                }
            }
            try rooms.append(new_room);
        }
    }
    state.player.pos = rooms.items[0].center();
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
            .pos = .{ .x = 0, .y = 0 },
        },
        .allocator = gpa.allocator(),
        .map = try newMapWithRooms(),
    };
}

fn tick() !void {
    state.drawMap();
    s.drawSprite(
        state.player.pos.x,
        state.player.pos.y,
        state.player.fg,
        state.player.bg,
        state.player.char,
    );
}

pub fn input(event: *app.Event) !void {
    if (event.isKeyDown(app.KEY_A)) {
        state.tryToMove(-1, 0);
    }
    if (event.isKeyDown(app.KEY_D)) {
        state.tryToMove(1, 0);
    }
    if (event.isKeyDown(app.KEY_W)) {
        state.tryToMove(0, -1);
    }
    if (event.isKeyDown(app.KEY_S)) {
        state.tryToMove(0, 1);
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
