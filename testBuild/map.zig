const app = @import("zRogue");
const a = app.Algorithms;
const std = @import("std");
const types = @import("types.zig");
const TileTypes = types.TileTypes;
const Rect = types.Rect;
const Player = @import("main.zig").Player;
const ArrayList = std.ArrayList;
const Vec2 = app.Geometry.Vec2;
const Quad = app.Algorithms.Quad;

pub fn i32tof32(x: i32) f32 {
    return @as(f32, @floatFromInt(x));
}
pub fn usizetof32(x: usize) f32 {
    return @as(f32, @floatFromInt(x));
}

const Self = @This();
tiles: ArrayList(TileTypes),
vis_tiles: ArrayList(bool),
rooms: ArrayList(Rect),
width: f32,
height: f32,

//pub fn scanner(self: *Self) app.Algorithms.Scanner {
//    return app.Algorithms.Scanner.init(self, TileTypes);
//}

pub fn computeFov(self: *Self, playerPos: Vec2, viewRange: i32) !void {
    const player_idx = self.vec2ToIndex(playerPos);
    if (player_idx) |idx| {
        self.vis_tiles.items[idx] = true;
    }

    for (app.Algorithms.CardinalList) |f| {
        var quad = a.Quad.new(playerPos, f);
        var sl = try a.Scanline.new(1, -1, 1);
        if (sl.depth * sl.depth > viewRange) {
            continue;
        }
        try self.scan(&sl, &quad);
    }
}

pub fn scan(self: *Self, firstLine: *a.Scanline, quad: *a.Quad) !void {
    var stack = std.ArrayList(a.Scanline).init(std.heap.page_allocator);
    defer stack.deinit();

    try stack.append(firstLine.*);

    while (stack.items.len != 0) {
        var scanline = stack.pop();
        var prev_tile: ?a.Tile = null;

        const tiles = try scanline.tiles();
        for (tiles) |tile| {
            const transformedQuad = quad.transform(tile);
            const idx = self.vec2ToIndex(transformedQuad);

            if (idx) |valid_idx| {
                if (self.isTileOpaque(valid_idx) or a.isSymmetric(&scanline, tile)) {
                    try self.markTileVisible(transformedQuad);
                }

                if (prev_tile) |prev| {
                    const previous_transformed = quad.transform(prev);
                    const prev_idx = self.vec2ToIndex(previous_transformed);

                    if (prev_idx) |valid_prev_idx| {
                        if (self.isTileOpaque(valid_prev_idx) and !self.isTileOpaque(valid_idx)) {
                            scanline.start_slope = a.slope(tile);
                        }

                        if (!self.isTileOpaque(valid_prev_idx) and self.isTileOpaque(valid_idx)) {
                            var next_line = scanline.next();
                            next_line.end_slope = a.slope(tile);
                            try stack.append(next_line);
                        }
                    }
                }

                prev_tile = tile;
            }
        }

        if (prev_tile) |prev| {
            const previous_transformed = quad.transform(prev);
            const prev_idx = self.vec2ToIndex(previous_transformed);
            if (prev_idx) |valid_prev_idx| {
                if (!self.isTileOpaque(valid_prev_idx)) {
                    try stack.append(scanline.next());
                }
            }
        }
    }
}
pub fn markTileVisible(self: *Self, pos: Vec2) !void {
    const idx = self.vec2ToIndex(pos);
    if (idx) |indx| {
        self.vis_tiles.items[indx] = true;
    }
}
// This is the index function to translate x/y coordinates
// to our flat array
pub fn index(x: f32, y: f32) usize {
    const idx = @as(usize, @intFromFloat((y * 80) + x));
    return idx;
}

pub fn applyRoomToMap(self: *Self, room: Rect) void {
    for (@as(usize, @intFromFloat(room.y + 1))..@as(usize, @intFromFloat(room.y2))) |y| {
        for (@as(usize, @intFromFloat(room.x + 1))..@as(usize, @intFromFloat(room.x2))) |x| {
            self.tiles.items[index(usizetof32(x), usizetof32(y))] = TileTypes.Floor;
        }
    }
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

pub fn horizontal_tunnel(self: *Self, x1: f32, x2: f32, y: f32) void {
    for (@as(usize, @intFromFloat(@min(x1, x2)))..(@as(usize, @intFromFloat(@max(x1, x2))) + 1)) |x| {
        const idx = index(usizetof32(x), y);
        if (0 < idx and idx < (80 * 50)) {
            self.tiles.items[idx] = TileTypes.Floor;
        }
    }
}
pub fn vertical_tunnel(self: *Self, y1: f32, y2: f32, x: f32) void {
    for (@as(usize, @intFromFloat(@min(y1, y2)))..(@as(usize, @intFromFloat(@max(y1, y2))) + 1)) |y| {
        const idx = index(x, usizetof32(y));
        if (0 < idx and idx < (80 * 50)) {
            self.tiles.items[idx] = TileTypes.Floor;
        }
    }
}

pub fn newMapWithRooms(alloc: std.mem.Allocator, player: *Player) !Self {
    var map = Self{
        .tiles = try std.ArrayList(TileTypes).initCapacity(alloc, 80 * 50),
        .vis_tiles = try std.ArrayList(bool).initCapacity(alloc, 80 * 50),
        .rooms = std.ArrayList(Rect).init(alloc),
        .width = 80,
        .height = 50,
    };

    for (0..(80 * 50)) |i| {
        try map.tiles.insert(i, TileTypes.Wall);
        try map.vis_tiles.insert(i, false);
    }

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
        for (map.rooms.items) |room| {
            if (room.intersects(new_room)) {
                new_room_ok = false;
            }
        }
        if (new_room_ok) {
            map.applyRoomToMap(new_room);
            if (map.rooms.items.len != 0) {
                const new = new_room.center();
                const prev = map.rooms.items[map.rooms.items.len - 1].center();

                if (rand.intRangeAtMost(i32, 0, 2) == 1) {
                    map.horizontal_tunnel(prev.x, new.x, prev.y);
                    map.vertical_tunnel(prev.y, new.y, new.x);
                } else {
                    map.horizontal_tunnel(prev.x, new.x, new.y);
                    map.vertical_tunnel(prev.y, new.y, prev.x);
                }
            }
            try map.rooms.append(new_room);
        }
    }
    player.pos = map.rooms.items[0].center();
    return map;
}

pub fn vec2ToIndex(self: *Self, vec: Vec2) ?u32 {
    const bounds = self.dimensions();
    const scratch = (vec.y * bounds.x);
    std.debug.print("bounds: {}, {}, scratch: {} vec2: {any}\n", .{ bounds.x, bounds.y, scratch, vec });
    const idx = @as(u32, @intFromFloat((scratch + vec.x)));
    if (idx > 0 and idx < self.tiles.items.len) {
        return idx;
    } else {
        return null;
    }
}

pub fn dimensions(self: *Self) Vec2 {
    return Vec2{ .x = self.width, .y = self.height };
}

pub fn isTileOpaque(self: *Self, idx: u32) bool {
    if (idx >= self.tiles.items.len) {
        return false;
    } else {
        return self.tiles.items[idx] == TileTypes.Wall;
    }
}
