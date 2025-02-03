const std = @import("std");

pub fn ServerTcp(comptime T: type, addr: std.net.Address, ptr_to_state: *T) type {
    return struct {
        addr: addr,
        state: ptr_to_state,
    };
}
const Self = @This();
addr: std.net.Address,

pub fn init(self: *Self, addr: std.net.Address) void {
    self.* = .{
        .addr = addr,
    };
}

pub fn run(self: *Self) !void {
    var serve = try self.addr.listen(.{});

    var conn = try serve.accept();
    std.log.info("CLIENT CONNECTED", .{});
    var counter: i32 = 0;

    while (true) {
        std.log.info("NEW LOOP", .{});
        var buf: [4096]u8 = undefined;
        const len = try conn.stream.read(&buf);
        std.log.info("Received: {} {s}", .{ counter, buf[0..len] });

        counter += 1;
        _ = try conn.stream.write("HELLO");
    }
    serve.deinit();
}
