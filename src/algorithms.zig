// https://www.albertford.com/shadowcasting/

const std = @import("std");

const Vec2 = struct {
    x: f32,
    y: f32,
};

const Cardinals = enum {
    north,
    south,
    east,
    west,
};

const Quadrant = struct {
    const Self = @This();
    cardinal: Cardinals,
    x: i32,
    y: i32,

    pub fn transform(self: *Self, tile: Vec2) Vec2 {
        const row = tile.x;
        const col = tile.y;

        if (self.cardinal == Cardinals.north) {
            return Vec2{
                .x = self.x + col,
                .y = self.y - row,
            };
        }
        if (self.cardinal == Cardinals.south) {
            return Vec2{
                .x = self.x + col,
                .y = self.y + row,
            };
        }
        if (self.cardinal == Cardinals.east) {
            return Vec2{
                .x = self.x + row,
                .y = self.y + col,
            };
        }
        if (self.cardinal == Cardinals.west) {
            return Vec2{
                .x = self.x - row,
                .y = self.y + col,
            };
        }
    }
};

const Tile = struct {
    depth: i32,
    column: i32,
};

const Scanline = struct {
    const Self = @This();
    depth: i32,
    start_slope: f64,
    end_slope: f64,

    pub fn new(depth: i32, start_slope: f64, end_slope: f64) Self {
        return Self{
            .depth = depth,
            .start_slope = start_slope,
            .end_slope = end_slope,
        };
    }
    pub fn tiles(self: *Self) std.ArrayList(Tile) {
        _ = self;
    }
    pub fn next(self: *Self) void {
        self.depth += 1;
    }
};

fn slope(tile: Tile) f64 {
    return @as(f64, @floatFromInt(2 * tile.column - 1)) / @as(f64, @floatFromInt(2 * tile.depth));
}

fn round_ties_up(r: f64) f64 {
    return std.math.floor(r + 0.5);
}
fn round_ties_down(r: f64) f64 {
    return std.math.ceil(r - 0.5);
}

fn isSymmetric(scanline: *Scanline, tile: Tile) bool {
    const col: i32 = @intFromFloat(tile.column);
    const dep: i32 = @intFromFloat(scanline.depth);
    return (col >= dep * @as(i32, @intFromFloat(scanline.start_slope)) and (col <= dep * @as(i32, @intFromFloat(scanline.end_slope))));
}


fn scanIterative(tile: Tile) void {

}

const FieldOfView = struct {
    ptr: *anyopaque,
    isOpaqueFn: *const fn (ptr: *anyopaque) anyerror!void,

    pub init(ptr: anytype) FieldOfView {
        const T = @TypeOf(ptr);
        const ptr_into = @typeInfo(T);

        const gen = struct {
            pub fn isOpaque(pointer: *anyopaque) anyerror!void {
                const self: T = @ptrCast(@alignCast(pointer));
                return ptr_info.Pointer.child.isOpaque(self);
            }
        };

        return .{
            .ptr = ptr,
            .isOpaqueFn = gen.isOpaque,
        };
    }
}

