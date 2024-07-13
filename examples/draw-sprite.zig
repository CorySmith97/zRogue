const app = @import("zRogue");
const s = app.Sprite;

pub fn tick() !void {
    s.drawSprite(5, 5, s.TEAL, s.BLACK, '@');
}

pub fn main() !void {
    try app.run(.{
        .title = "Draw Sprite",
        .tick = tick,
    });
}
