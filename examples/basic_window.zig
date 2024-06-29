const std = @import("std");
const app = @import("zRogue");

pub fn main() !void {
    try app.run(.{
        .title = "Basic Window",
    });
}
