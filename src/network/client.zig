const std = @import("std");

const Self = @This();
host_addr: std.net.Address,
host_port: []u8,
