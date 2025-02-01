const std = @import("std");
const zRogue = @import("zRogue");
const run = zRogue.run;
const app = zRogue.App;
const s = app.Sprite;
const a = zRogue.Algorithms;
const Map = @import("map.zig");
const types = @import("types.zig");
const Vec2 = zRogue.Geometry.Vec2;
const TileTypes = types.TileTypes;
const ArrayList = std.ArrayList;

pub const Player = struct {
    const Self = @This();
    fg: s.Color,
    bg: s.Color,
    char: u8,
    pos: Vec2,
    view: View,
};

pub const Monster = struct {
    const Self = @This();
    id: u32,
    pos: Vec2,
    fg: s.Color,
    bg: s.Color,
    char: u8,

    pub fn draw(self: *const Self) void {
        s.drawSprite(self.pos.x, self.pos.y, self.fg, self.bg, self.char);
    }
    pub fn speak(self: *const Self) !void {
        var buf: [100]u8 = undefined;
        const formatted_string = try std.fmt.bufPrint(&buf, "Monster {} says hello", .{self.id});
        s.print(1, 1, s.WHITE, s.BLACK, formatted_string);
    }
};

pub const View = struct {
    visible_tiles: ArrayList(Vec2),
    range: i32,
};

pub const State = struct {
    const Self = @This();
    player: Player,
    monsters: ArrayList(Monster),
    allocator: std.mem.Allocator,
    map: Map,

    pub fn drawMap(self: *Self) void {
        var x: f32 = 0;
        var y: f32 = 0;

        for (self.map.tiles.items, self.map.visible_tiles.items, self.map.revealed_tiles.items) |cell, vis, rev| {
            if (rev) {
                switch (cell) {
                    TileTypes.Wall => s.drawSprite(x, y, s.GRAY, s.BLACK, '#'),
                    TileTypes.Floor => s.drawSprite(x, y, s.GRAY, s.BLACK, '.'),
                }
            }
            if (vis) {
                switch (cell) {
                    TileTypes.Wall => s.drawSprite(x, y, s.DARK_BLUE, s.PASTEL_ORANGE, '#'),
                    TileTypes.Floor => s.drawSprite(x, y, s.TEAL, s.PASTEL_ORANGE, '.'),
                }
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
    pub fn fov(self: *Self) !void {
        for (0..self.map.visible_tiles.items.len, self.map.visible_tiles.items) |i, vis| {
            if (self.map.revealed_tiles.items[i] == false) {
                self.map.revealed_tiles.items[i] = vis;
            }
        }
        for (0..self.map.visible_tiles.items.len) |i| {
            self.map.visible_tiles.items[i] = false;
        }
        try a.FieldOfView(Map, &self.map, self.player.pos, self.player.view.range);
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
        .monsters = ArrayList(Monster).init(allocator),
        .allocator = allocator,
        .map = m,
    };

    for (1..m.rooms.items.len) |i| {
        const center = m.rooms.items[i].center();

        try state.monsters.append(Monster{
            .id = @intCast(i),
            .pos = center,
            .fg = s.PASTEL_RED,
            .bg = s.BLACK,
            .char = 'g',
        });
    }
    try state.fov();
}

fn tick() !void {
    state.drawMap();
    for (state.monsters.items) |monster| {
        const idx = state.map.vec2ToIndex(monster.pos);
        if (idx) |i| {
            if (state.map.visible_tiles.items[i]) {
                monster.draw();
                try monster.speak();
            }
        }
    }
    s.drawSprite(
        state.player.pos.x,
        state.player.pos.y,
        state.player.fg,
        state.player.bg,
        state.player.char,
    );
    s.print(0, 0, s.WHITE, s.BLACK, [_]u8{196} ** 10 ++ ">LOG<" ++ [_]u8{196} ** 65);
    s.drawVertLine(10, 0, 40, s.PASTEL_RED, s.WHITE);
}

pub fn input(event: *zRogue.Event) !void {
    if (event.isKeyDown(zRogue.KEY_A)) {
        state.tryToMove(-1, 0);
        try state.fov();
    }
    if (event.isKeyDown(zRogue.KEY_D)) {
        state.tryToMove(1, 0);
        try state.fov();
    }
    if (event.isKeyDown(zRogue.KEY_W)) {
        state.tryToMove(0, -1);
        try state.fov();
    }
    if (event.isKeyDown(zRogue.KEY_S)) {
        state.tryToMove(0, 1);
        try state.fov();
    }
    if (event.isKeyDown(zRogue.KEY_Escape)) {
        event.windowShouldClose(true);
    }
}

pub fn cleanup() !void {
    m.tiles.deinit();
    m.rooms.deinit();
    m.visible_tiles.deinit();
    m.revealed_tiles.deinit();
    state.monsters.deinit();
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
