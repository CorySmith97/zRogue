const std = @import("std");
const app = @import("zRogue");
const run = app.run;
const s = app.Sprite;
const Map = @import("map.zig");
const types = @import("types.zig");
const Vec2 = app.Geometry.Vec2;
const TileTypes = types.TileTypes;
const ArrayList = std.ArrayList;

/// end map.zig
pub const Player = struct {
    const Self = @This();
    fg: s.Color,
    bg: s.Color,
    char: u8,
    pos: Vec2,
    view: View,
};
pub const View = struct {
    visible_tiles: ArrayList(Vec2),
    range: i32,
};

pub const State = struct {
    const Self = @This();
    player: Player,
    allocator: std.mem.Allocator,
    map: Map,

    pub fn drawMap(self: *Self) void {
        var x: f32 = 0;
        var y: f32 = 0;

        for (self.map.tiles.items) |cell| {
            //std.debug.print("{any}\n", .{cell});
            switch (cell) {
                TileTypes.Wall => s.drawSprite(x, y, s.GREEN, s.BLACK, '#'),
                TileTypes.Floor => s.drawSprite(x, y, s.PASTEL_PINK, s.BLACK, '.'),
            }
            x += 1;
            if (x >= 80) {
                x = 0;
                y += 1;
            }
        }
    }
    pub fn tryToMove(self: *Self, delta_x: f32, delta_y: f32) void {
        const destination_idx = Map.index(self.player.pos.x + delta_x, self.player.pos.y + delta_y);
        if (self.map.tiles.items[destination_idx] != TileTypes.Wall) {
            self.player.pos.x = @min(79, @max(0, self.player.pos.x + delta_x));
            self.player.pos.y = @min(49, @max(0, self.player.pos.y + delta_y));
        }
    }
    // https://www.albertford.com/shadowcasting/
    pub fn fov(self: *Self) void {
        _ = self;
    }
};

pub var state: State = undefined;
var m: Map = undefined;
var gpa: std.heap.GeneralPurposeAllocator(.{}) = undefined;

fn init() !void {
    gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var player: Player = .{
        .fg = s.YELLOW,
        .bg = s.BLACK,
        .char = '@',
        .pos = undefined,
        .view = .{
            .visible_tiles = std.ArrayList(Vec2).init(allocator),
            .range = 8,
        },
    };

    m = try Map.newMapWithRooms(allocator, &player);

    state = .{
        .player = player,
        .allocator = allocator,
        .map = m,
    };
    m.computeFov(player.pos);
}

fn tick() !void {
    state.drawMap();
    s.drawSprite(
        state.player.pos.x,
        state.player.pos.y,
        state.player.fg,
        state.player.bg,
        state.player.char,
    );
}

pub fn input(event: *app.Event) !void {
    if (event.isKeyDown(app.KEY_A)) {
        state.tryToMove(-1, 0);
    }
    if (event.isKeyDown(app.KEY_D)) {
        state.tryToMove(1, 0);
    }
    if (event.isKeyDown(app.KEY_W)) {
        state.tryToMove(0, -1);
    }
    if (event.isKeyDown(app.KEY_S)) {
        state.tryToMove(0, 1);
    }
    if (event.isKeyDown(app.KEY_Escape)) {
        event.windowShouldClose(true);
    }
}

pub fn cleanup() !void {
    m.tiles.deinit();
    m.rooms.deinit();
    m.vis_tiles.deinit();
    _ = gpa.deinit();
}

pub fn main() !void {
    try run(.{
        .title = "zRogue",
        .init = init,
        .tick = tick,
        .events = input,
        .cleanup = cleanup,
    });
}
