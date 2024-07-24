const std = @import("std");

pub fn i32tof32(x: i32) f32 {
    return @as(f32, @floatFromInt(x));
}
