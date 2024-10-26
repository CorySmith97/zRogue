const std = @import("std");

const Self = @This();
socket: std.posix.socket_t,
address: std.net.Address,

pub fn init(self: *Self, address: []u8, port: u16) !void {
    _ = self; // autofix
    _ = address; // autofix
    _ = port; // autofix
}
