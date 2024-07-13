const std = @import("std");
const ArrayList = std.ArrayList;
const app = @import("zRogue");

const TileType = enum { Wall, Floor };

var map: ArrayList(TileType) = undefined;
var gpa: std.heap.GeneralPurposeAllocator = undefined;

pub fn init() !void {
    gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    map.init(allocator);
}

pub fn tick() !void {}

pub fn cleanup() !void {
    _ = gpa.deinit();
    map.deinit();
}

pub fn main() !void {
    app.run(.{
        .init = init,
        .tick = tick,
        .cleanup = cleanup,
        .title = "Draw a Map",
    });
}
