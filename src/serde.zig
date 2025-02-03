const std = @import("std");
const fs = std.fs;
const SerdeTypes = enum {
    json,
    binary,
};

pub fn serialize(
    comptime T: type,
    ser_type: SerdeTypes,
    file: []const u8,
) !void {
    _ = T;
    _ = ser_type;
    _ = file;
}
