const std = @import("std");
const Vec2 = @import("../math/geometry.zig").Vec2;

pub fn astar(comptime T: type, map: *anyopaque, origin: Vec2, target: Vec2) void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const self: *T = @ptrCast(@alignCast(map));
    _ = origin;
    _ = target;
    _ = allocator;
    _ = self;
}
