
const std = @import("std");
const zRogue = @import("zRogue");
const run = zRogue.run;
const app = zRogue.App;
const s = app.Sprite;

var sprite_counter: u8 = 0;

pub fn main() !void {
        try run(.{
        .title = "zRogue",
        .tick = tick,
        .events = events,
    });
}

pub fn tick() !void {
    var buf: [100]u8 = undefined;
    const string = try std.fmt.bufPrint(&buf, "sprite count: {d}", .{sprite_counter});
    s.drawSprite(
        10,
        10,
        s.TEAL,
        s.BLACK,
        sprite_counter,
    );

    s.print(15, 10, s.WHITE, s.BLACK, string);
}

pub fn events(event: *zRogue.Event) !void {
    if (event.isKeyDown(zRogue.KEY_A)) {
        sprite_counter -= 1;
    }
    if (event.isKeyDown(zRogue.KEY_D)) {
        sprite_counter += 1;
    }
}
