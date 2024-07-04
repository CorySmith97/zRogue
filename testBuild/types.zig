const std = @import("std");

pub const TileTypes = enum {
    Wall,
    Floor,
};
pub const Vec2 = struct {
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
};
