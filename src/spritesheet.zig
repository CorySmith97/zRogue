const std = @import("std");

const Self = @This();
width: i32,
height: i32,

pub fn init(width: i32, height: i32) Self {
    return .{
        .width = width,
        .height = height,
    };
}
