const std = @import("std");
const zRogue = @import("zRogue");
const run = zRogue.run;
const app = zRogue.App;
const s = app.Sprite;

var sprite_counter: u8 = 0;
var selected_color: u8 = 0;
var app_desc: zRogue.AppDesc = undefined;

const C = struct { color: s.Color, name: []const u8 };

const colors = &[_]C{
    .{ .name = "pastel green", .color = s.PASTEL_GREEN },
    .{ .name = "pastel pink", .color = s.PASTEL_PINK },
    .{ .name = "pastel purple", .color = s.PASTEL_PURPLE },
    .{ .name = "pastel blue", .color = s.PASTEL_BLUE },
    .{ .name = "pastel red", .color = s.PASTEL_RED },
    .{ .name = "pastel yellow", .color = s.PASTEL_YELLOW },
    .{ .name = "pastel orange", .color = s.PASTEL_ORANGE },
    .{ .name = "white", .color = s.WHITE },
    .{ .name = "gray", .color = s.GRAY },
    .{ .name = "magenta", .color = s.MAGENTA },
    .{ .name = "mustard", .color = s.MUSTARD },
    .{ .name = "purple", .color = s.PURPLE },
    .{ .name = "dark blue", .color = s.DARK_BLUE },
};

var animation_h = s.Animation{
    .frame_count = 0,
    .frame_speed = 30,
    .font_size = 2,
    .x = 10,
    .y = 40,
    .frames = @constCast(
        &[_]s.AnimationFrame{
            .{ .fg = s.GRAY, .bg = s.BLACK, .char = 'h' },
            .{ .fg = s.GRAY, .bg = s.BLACK, .char = 'h' },
            .{ .fg = s.WHITE, .bg = s.BLACK, .char = 'h' },
            .{ .fg = s.WHITE, .bg = s.BLACK, .char = 'h' },
        },
    ),
};
var animation_e = s.Animation{
    .frame_count = 0,
    .frame_speed = 30,
    .font_size = 2,
    .x = 13,
    .y = 40,
    .frames = @constCast(
        &[_]s.AnimationFrame{
            .{ .fg = s.WHITE, .bg = s.BLACK, .char = 'e' },
            .{ .fg = s.GRAY, .bg = s.BLACK, .char = 'e' },
            .{ .fg = s.GRAY, .bg = s.BLACK, .char = 'e' },
            .{ .fg = s.WHITE, .bg = s.BLACK, .char = 'e' },
        },
    ),
};
var animation_y = s.Animation{
    .frame_count = 0,
    .frame_speed = 30,
    .font_size = 2,
    .x = 16,
    .y = 40,
    .frames = @constCast(
        &[_]s.AnimationFrame{
            .{ .fg = s.WHITE, .bg = s.BLACK, .char = 'y' },
            .{ .fg = s.WHITE, .bg = s.BLACK, .char = 'y' },
            .{ .fg = s.GRAY, .bg = s.BLACK, .char = 'y' },
            .{ .fg = s.GRAY, .bg = s.BLACK, .char = 'y' },
        },
    ),
};

pub fn main() !void {
    app_desc = .{
        .title = "zRogue",
        .init = init,
        .tick = tick,
        .events = events,
        //.h_tile_count = 100,
        //.v_tile_count = 50,
        //.screen_height = 800,
        //.screen_width = 1200,
    };
    try run(app_desc);
}

pub fn init() !void {}

pub fn tick() !void {
    const mouse_pos = zRogue.getMousePos();
    var buf: [1000]u8 = undefined;
    const string = try std.fmt.bufPrint(&buf, "sprite count: {d}", .{sprite_counter});

    if (selected_color == colors.len) {
        selected_color = 0;
    }
    if (selected_color > colors.len) {
        selected_color = colors.len - 1;
    }

    s.drawBox(6, 35, 17, 21, s.PASTEL_PINK, s.BLACK);
    s.print(7, 19, s.WHITE, s.BLACK, "Press 'A' or 'D' to explore");
    s.drawBox(6, 35, 12, 16, s.PASTEL_PINK, s.BLACK);
    s.print(7, 14, s.WHITE, s.BLACK, "Press 'W' or 'S' for color");

    s.print(13, 24, s.WHITE, s.BLACK, string);
    s.drawBox(6, 33, 22, 26, s.PASTEL_PINK, s.BLACK);

    // Selected Color
    //s.printC(7, 28, colors[selected_color].color, s.BLACK, colors[selected_color].name, 2);
    s.drawBox(6, 33, 27, 31, s.PASTEL_PINK, s.BLACK);

    s.drawBox(40, 74, 10, 44, s.PASTEL_PINK, s.TRANSPARENT);
    //s.drawSpriteC(8, 23, colors[selected_color].color, s.BLACK, sprite_counter, 3);
    //for (0..255) |sprite| {
    //    const x_offset = sprite % 16 * 2;
    //    const y_offset = sprite / 16 * 2;
    //    const x: f32 = @floatFromInt(41 + x_offset);
    //    const y: f32 = @floatFromInt(11 + y_offset);
    //    s.drawSpriteC(x, y, s.WHITE, s.TRANSPARENT, @intCast(sprite), 2);
    //}

    //animation_h.draw();
    //animation_e.draw();
    //animation_y.draw();

    //s.printC(30, 5, s.PASTEL_GREEN, s.BLACK, "Sprite Viewer", 2);

    s.drawSprite(
        @floor(mouse_pos.x * 80 / 1200),
        @floor(mouse_pos.y * 50 / 800),
        s.YELLOW,
        s.TRANSPARENT,
        'X',
    );
}

pub fn events(event: *zRogue.Event) !void {
    @setRuntimeSafety(false);
    if (event.isKeyDown(zRogue.Keys.KEY_Escape)) {
        event.windowShouldClose(true);
    }
    if (event.isKeyDown(zRogue.Keys.KEY_A)) {
        sprite_counter -= 1;
    }
    if (event.isKeyDown(zRogue.Keys.KEY_D)) {
        sprite_counter += 1;
    }
    if (event.isKeyDown(zRogue.Keys.KEY_W)) {
        selected_color += 1;
    }
    if (event.isKeyDown(zRogue.Keys.KEY_S)) {
        selected_color -= 1;
    }
}
