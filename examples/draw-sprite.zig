const zRogue = @import("zRogue");
const app = @import("zRogue").App;
const s = app.Sprite;

pub fn tick() !void {
    s.drawSprite(
        10,
        10,
        s.TEAL,
        s.BLACK,
        '@',
    );

    s.drawSprite(
        20,
        10,
        .{ .r = 1.0, .g = 0.2, .b = 0.4 },
        .{ .r = 0.0, .g = 0.0, .b = 0.0 },
        '@',
    );

    s.print(10, 5, s.WHITE, s.BLACK, "This is some test text");
}

pub fn main() !void {
    try zRogue.run(.{
        .title = "Draw Sprite",
        .tick = tick,
    });
}
