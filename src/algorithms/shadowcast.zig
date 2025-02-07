const std = @import("std");
const Vec2 = @import("../math/geometry.zig").Vec2;
const i32tof32 = @import("../util.zig").i32tof32;
const ArrayList = std.ArrayList;
const print = std.debug.print;
const assert = std.debug.assert;

const Cardinal = enum { North, South, East, West };
const CardinalList = [4]Cardinal{
    Cardinal.North,
    Cardinal.South,
    Cardinal.East,
    Cardinal.West,
};
const Quad = struct {
    origin: Vec2,
    cardinal: Cardinal,

    fn new(point: Vec2, card: Cardinal) Quad {
        return Quad{
            .origin = point,
            .cardinal = card,
        };
    }
    fn transform(self: *Quad, tile: Tile) Vec2 {
        switch (self.cardinal) {
            Cardinal.North => return Vec2{ .x = self.origin.x + i32tof32(tile.column), .y = self.origin.y - i32tof32(tile.depth) },
            Cardinal.South => return Vec2{ .x = self.origin.x + i32tof32(tile.column), .y = self.origin.y + i32tof32(tile.depth) },
            Cardinal.East => return Vec2{ .x = self.origin.x + i32tof32(tile.depth), .y = self.origin.y + i32tof32(tile.column) },
            Cardinal.West => return Vec2{ .x = self.origin.x - i32tof32(tile.depth), .y = self.origin.y + i32tof32(tile.column) },
        }
    }
};

const Tile = struct {
    depth: i32,
    column: i32,
};

const Scanline = struct {
    depth: i32,
    start_slope: f32,
    end_slope: f32,

    fn new(depth: i32, start_slope: f32, end_slope: f32) !Scanline {
        return Scanline{
            .depth = depth,
            .start_slope = start_slope,
            .end_slope = end_slope,
        };
    }
    fn tiles(
        self: *Scanline,
        allocator: std.mem.Allocator,
    ) ![]Tile {
        const start = roundTiesUp(i32tof32(self.depth) * self.start_slope);
        const end = roundTiesDown(i32tof32(self.depth) * self.end_slope);

        const range = end - start + 1;
        var t = try allocator.alloc(Tile, @intCast(@abs(range)));

        var column = start;
        for (0..@intCast(range)) |i| {
            //print("Column: {}, Range: {}\n", .{ column, range });
            t[i] = Tile{ .depth = self.depth, .column = column };
            column += 1;
        }

        return t;
    }
    fn next(self: *Scanline) Scanline {
        return Scanline{
            .depth = self.depth + 1,
            .start_slope = self.start_slope,
            .end_slope = self.end_slope,
        };
    }
};

fn roundTiesUp(r: f32) i32 {
    return @as(i32, @intFromFloat(std.math.floor(r + 0.5)));
}
fn roundTiesDown(r: f32) i32 {
    return @as(i32, @intFromFloat(std.math.ceil(r - 0.5)));
}
fn slope(tile: Tile) f32 {
    return i32tof32(2 * tile.column - 1) / i32tof32(2 * tile.depth);
}
fn isSymmetric(scanline: *Scanline, tile: Tile) bool {
    const column = @as(f32, @floatFromInt(tile.column));
    const depth = @as(f32, @floatFromInt(scanline.depth));
    return (column >= depth * scanline.start_slope) and (column <= depth * scanline.end_slope);
}

/// Interface to compute field of view
/// MUST HAVE ITEMS IN MAP STRUCT
/// - tiles: ArrayList(**Your tile type**),
/// - visible_tiles: ArrayList(bool),
/// - pub fn isTileOpaque(self: *Self) bool;
/// - pub fn vec2ToIndex(self: *Self, vec: Vec2) u32;
/// This function will populate the visible_tiles array
/// with true for visible tiles, and false for non-visible
pub fn fieldOfView(comptime T: type, map: *anyopaque, player_pos: Vec2, range: i32) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const self: *T = @ptrCast(@alignCast(map));

    // verify that the struct passed has the proper methods and fields
    assert(std.meta.hasMethod(T, "isTileOpaque"));
    assert(std.meta.hasMethod(T, "vec2ToIndex"));
    assert(@hasField(T, "tiles"));
    assert(@hasField(T, "visible_tiles"));

    // Mark the player origin to visible
    if (self.*.vec2ToIndex(player_pos)) |pos| {
        self.*.visible_tiles.items[pos] = true;
    }

    // iterate through all the directions to run our shadowcast algorithm
    // This algorithm is gotten from the below link.
    // https://www.albertford.com/shadowcasting/
    inline for (CardinalList) |dir| {
        var quad = Quad.new(player_pos, dir);
        var scanline = try Scanline.new(1, -1, 1);
        const s = &scanline;
        _ = s;

        var stack = ArrayList(Scanline).init(allocator);
        defer stack.deinit();

        try stack.append(scanline);

        while (stack.items.len != 0) {
            var sl = stack.pop();
            var prev_tile: ?Tile = null;
            if (sl.depth * sl.depth > range * range) {
                continue;
            }

            const tiles = try sl.tiles(allocator);
            defer allocator.free(tiles);
            for (tiles) |tile| {
                const transformed_quad = quad.transform(tile);
                const idx = self.*.vec2ToIndex(transformed_quad);
                if (idx) |valid_idx| {
                    if (self.*.isTileOpaque(valid_idx) or isSymmetric(&sl, tile)) {
                        try self.*.markTileVisible(transformed_quad);
                    }
                    if (prev_tile) |prev| {
                        const previous_transformed_quad = quad.transform(prev);
                        const prev_idx = self.*.vec2ToIndex(previous_transformed_quad);

                        if (prev_idx) |valid_prev_idx| {
                            if (self.*.isTileOpaque(valid_prev_idx) and !self.*.isTileOpaque(valid_idx)) {
                                sl.start_slope = slope(tile);
                            }
                            if (!self.*.isTileOpaque(valid_prev_idx) and self.*.isTileOpaque(valid_idx)) {
                                var nextline = sl.next();
                                nextline.end_slope = slope(tile);
                                try stack.append(nextline);
                            }
                        }
                    }
                }
                prev_tile = tile;
            }
            if (prev_tile) |prev| {
                const previous_transformed_quad = quad.transform(prev);
                const prev_idx = self.*.vec2ToIndex(previous_transformed_quad);
                if (prev_idx) |valid_prev_idx| {
                    if (!self.*.isTileOpaque(valid_prev_idx)) {
                        try stack.append(sl.next());
                    }
                }
            }
        }
    }
}
