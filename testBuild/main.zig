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
const Camera2D = zRogue.Camera2D;

pub const Player = struct {
    const Self = @This();
    fg: s.Color,
    bg: s.Color,
    char: u32,
    pos: Vec2,
    view: View,
};

pub const Monster = struct {
    const Self = @This();
    id: u32,
    pos: Vec2,
    fg: s.Color,
    bg: s.Color,
    char: u32,

    pub fn draw(self: *const Self, camera: *Camera2D) void {
        s.drawSpriteCamera(camera, self.pos.x, self.pos.y, self.fg, self.bg, @intCast(self.char));
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

    pub fn drawMap(self: *Self, camera: *zRogue.Camera2D) void {
        var x: f32 = 0;
        var y: f32 = 0;

        for (self.map.tiles.items, self.map.visible_tiles.items, self.map.revealed_tiles.items) |cell, vis, rev| {
            if (rev) {
                switch (cell) {
                    TileTypes.Wall => s.drawSpriteCamera(camera, x, y, s.DARK_BLUE, s.BLACK, 184),
                    TileTypes.Floor => s.drawSpriteCamera(camera, x, y, s.DARK_BLUE, s.BLACK, 87),
                }
            }
            if (vis) {
                switch (cell) {
                    TileTypes.Wall => s.drawSpriteCamera(camera, x, y, s.WHITE, s.PASTEL_ORANGE, 184),
                    TileTypes.Floor => s.drawSpriteCamera(camera, x, y, s.WHITE, s.PASTEL_ORANGE, 87),
                }
            }
            x += 1;
            if (x >= 100) {
                x = 0;
                y += 1;
            }
        }
    }
    pub fn tryToMove(self: *Self, delta_x: f32, delta_y: f32) void {
        const destination_idx = Map.index(self.player.pos.x + delta_x, self.player.pos.y + delta_y);
        if (self.map.tiles.items[destination_idx] != TileTypes.Wall) {
            self.player.pos.x = @min(99, @max(0, self.player.pos.x + delta_x));
            self.player.pos.y = @min(99, @max(0, self.player.pos.y + delta_y));
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
var spritesheets: std.StringHashMap(zRogue.SpritesheetInfo) = undefined;
var cam: zRogue.Camera2D = .{};

fn init() !void {
    gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    spritesheets = try zRogue.loadSpritesheets(allocator, @constCast(
        &[_]zRogue.SpritesheetParams{
            .{ .name = "src/assets/VGA8x16.bmp", .sprite_size = .{ 8, 16 }, .has_alpha = false },
            .{ .name = "src/assets/roguelike_1.bmp", .sprite_size = .{ 16, 16 }, .has_alpha = false },
            .{ .name = "src/assets/fan.bmp", .sprite_size = .{ 16, 16 }, .has_alpha = true },
        },
    ));
    var player: Player = .{
        .fg = s.MAGENTA,
        .bg = s.TRANSPARENT,
        .char = 324,
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
            .fg = s.PASTEL_GREEN,
            .bg = s.TRANSPARENT,
            .char = 311,
        });
    }
    try state.fov();
}

fn tick() !void {
    zRogue.changeActiveShader("basic");
    try zRogue.setActiveSpritesheet(&spritesheets, "src/assets/fan.bmp");
    state.drawMap(&cam);
    for (state.monsters.items) |monster| {
        const idx = state.map.vec2ToIndex(monster.pos);
        if (idx) |i| {
            if (state.map.visible_tiles.items[i]) {
                monster.draw(&cam);
            }
        }
    }
    s.drawSpriteCamera(
        &cam,
        state.player.pos.x,
        state.player.pos.y,
        state.player.fg,
        state.player.bg,
        @intCast(state.player.char),
    );
    zRogue.changeActiveShader("ui");
    try zRogue.setActiveSpritesheet(&spritesheets, "src/assets/VGA8x16.bmp");
    for (state.monsters.items) |monster| {
        const idx = state.map.vec2ToIndex(monster.pos);
        if (idx) |i| {
            if (state.map.visible_tiles.items[i]) {
                try monster.speak();
            }
        }
    }
    s.print(0, 0, s.WHITE, s.BLACK, [_]u8{196} ** 10 ++ ">LOG<" ++ [_]u8{196} ** 65);
    s.drawBox(70, 81, 0, 50, s.WHITE, s.TRANSPARENT);
}

pub fn input(event: *zRogue.Event) !void {
    if (event.getMiddleMouseDelta()) |delta| {
        cam.offset[0] += delta[0] * 0.001;
        cam.offset[1] -= delta[1] * 0.001;
    }
    if (event.isKeyDown(zRogue.Keys.KEY_A)) {
        state.tryToMove(-1, 0);
        try state.fov();
    }
    if (event.isKeyDown(zRogue.Keys.KEY_D)) {
        state.tryToMove(1, 0);
        try state.fov();
    }
    if (event.isKeyDown(zRogue.Keys.KEY_W)) {
        state.tryToMove(0, -1);
        try state.fov();
    }
    if (event.isKeyDown(zRogue.Keys.KEY_S)) {
        state.tryToMove(0, 1);
        try state.fov();
    }
    if (event.isKeyDown(zRogue.Keys.KEY_Escape)) {
        event.windowShouldClose(true);
    }
}

pub fn cleanup() !void {
    spritesheets.deinit();
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
