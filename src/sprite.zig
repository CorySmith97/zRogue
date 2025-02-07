const std = @import("std");
const Vec2 = @import("root.zig").Vec2;

const Self = @This();
id: u32,
spritesheet: u32,
name: []const u8,
spritesheet_loc: Vec2,
sprite_size: Vec2,
