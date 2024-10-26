const std = @import("std");
const posix = std.posix;

const pos = struct {
    x: i32,
    y: i32,
};
pub fn main() !void {
    const sock = try posix.socket(posix.AF.INET, posix.SOCK.DGRAM, 0);
    defer posix.close(sock);
    //var server: zRogue.Network.serverTCP = undefined;
    const addr = std.net.Address.initIp4(.{ 127, 0, 0, 1 }, 4080);
    try posix.bind(sock, &addr.any, addr.getOsSockLen());

    var client_sock: std.net.Address = undefined;
    var client_addr: posix.socklen_t = undefined;
    var items = std.ArrayList(pos).init(std.heap.page_allocator);
    try items.append(.{ .x = 1, .y = 2 });

    var buf: [1024]u8 = undefined;
    while (true) {
        const len = try posix.recvfrom(sock, &buf, 0, &client_sock.any, &client_addr);
        std.log.info("{s}", .{buf[0..len]});
        _ = try posix.sendto(sock, "HELLO", 0, &client_sock.any, client_addr);
    }
}
