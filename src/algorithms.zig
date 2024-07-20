const std = @import("std");
const Vec2 = @import("geometry.zig").Vec2;

pub fn i32tof32(x: i32) f32 {
    return @as(f32, @floatFromInt(x));
}

pub const Cardinal = enum { North, South, East, West };
pub const CardinalList = [4]Cardinal{ Cardinal.North, Cardinal.South, Cardinal.East, Cardinal.West };
pub const Quad = struct {
    origin: Vec2,
    cardinal: Cardinal,

    pub fn new(point: Vec2, card: Cardinal) Quad {
        return Quad{
            .origin = point,
            .cardinal = card,
        };
    }
    pub fn transform(self: *Quad, tile: Tile) Vec2 {
        switch (self.cardinal) {
            Cardinal.North => return Vec2{ .x = self.origin.x + i32tof32(tile.column), .y = self.origin.y - i32tof32(tile.depth) },
            Cardinal.South => return Vec2{ .x = self.origin.x + i32tof32(tile.column), .y = self.origin.y + i32tof32(tile.depth) },
            Cardinal.East => return Vec2{ .x = self.origin.x + i32tof32(tile.depth), .y = self.origin.y + i32tof32(tile.column) },
            Cardinal.West => return Vec2{ .x = self.origin.x - i32tof32(tile.depth), .y = self.origin.y + i32tof32(tile.column) },
        }
    }
};

pub const Tile = struct {
    depth: i32,
    column: i32,
};

pub const Scanline = struct {
    depth: i32,
    start_slope: f32,
    end_slope: f32,
    allocator: std.mem.Allocator,

    pub fn new(depth: i32, start_slope: f32, end_slope: f32) !Scanline {
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        return Scanline{
            .depth = depth,
            .start_slope = start_slope,
            .end_slope = end_slope,
            .allocator = arena.allocator(),
        };
    }
    pub fn tiles(self: *Scanline) ![]Tile {
        var allocator = std.heap.page_allocator;

        const start = roundTiesUp(i32tof32(self.depth) * self.start_slope);
        const end = roundTiesDown(i32tof32(self.depth) * self.end_slope);

        const range = end - start + 1;
        var t = try allocator.alloc(Tile, @intCast(@abs(range)));

        var i: usize = 0;
        var column = start;
        while (column < end) : (column += 1) {
            t[i] = Tile{ .depth = self.depth, .column = column };
            i += 1;
        }

        std.debug.print("tiles: {any}, range: {}\n", .{ t, range });
        return t;
    }
    pub fn next(self: *Scanline) Scanline {
        return Scanline{
            .depth = self.depth + 1,
            .start_slope = self.start_slope,
            .end_slope = self.end_slope,
            .allocator = self.allocator,
        };
    }
};

pub const FOV = struct {
    tes: i32,
};

pub fn roundTiesUp(r: f32) i32 {
    return @as(i32, @intFromFloat(std.math.floor(r + 0.5)));
}
pub fn roundTiesDown(r: f32) i32 {
    return @as(i32, @intFromFloat(std.math.ceil(r - 0.5)));
}
pub fn slope(tile: Tile) f32 {
    return @as(f32, @floatFromInt(2 * tile.column - 1 / 2 * tile.depth));
}
pub fn isSymmetric(scanline: *Scanline, tile: Tile) bool {
    const column = @as(f32, @floatFromInt(tile.column));
    const depth = @as(f32, @floatFromInt(tile.depth));
    return (column >= depth * scanline.start_slope) and (column <= depth * scanline.end_slope);
}

pub const Scanner = struct {
    //radius: i32,
    //quad: Quad,
    map: *anyopaque,
    isOpaqueFn: *const fn (ptr: *anyopaque, idx: u32) bool,

    pub fn init(ptr: anytype) Scanner {
        const T = @TypeOf(ptr);
        const ptr_info = @typeInfo(T);

        const gen = struct {
            pub fn isOpaque(pointer: *anyopaque, idx: u32) bool {
                const self: T = @ptrCast(@alignCast(pointer));
                return ptr_info.Pointer.child.isTileOpaque(self, idx);
            }
        };

        return .{
            .map = ptr,
            .isOpaqueFn = gen.isOpaque,
        };
    }
    fn isOpaque(self: Scanner, idx: u32) bool {
        return self.isOpaqueFn(self.map, idx);
    }
};

pub fn fieldOfView(map: anytype) FOV {
    const T = @TypeOf(map);
    const m_info = @typeInfo(T);

    std.debug.print("Test Type:{any}, point: {}\n", .{ T, m_info });
    return FOV{
        .tes = 3,
    };
}
