const std = @import("std");
const math = @import("zlm.zig");

const math_u8 = math.SpecializeOn(u8);

const Self = @This();

pos_x: i32,
pos_y: i32,
vao: u32,
glyph: u8,
background_color: math_u8.Vec3,
foreground_color: math_u8.Vec3,
