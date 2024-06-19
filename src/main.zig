const std = @import("std");
const arena = std.heap.ArenaAllocator;
const app = @import("zRogue.zig");
const run = app.run;
const sh = @import("spritesheet.zig");
const c = @import("c.zig");

const Player = struct {
    fg: sh.Color,
    bg: sh.Color,
    char: u8,
    x: f32,
    y: f32,
};
const State = struct { player: Player };

var state: State = undefined;

fn init() void {
    state = .{
        .player = .{
            .fg = sh.DARK_BLUE,
            .bg = sh.BLACK,
            .char = '@',
            .x = 10,
            .y = 5,
        },
    };
}

fn tick() void {
    sh.drawSprite(4, 10, sh.TEAL, sh.BLACK, '1');
    sh.drawSprite(5, 10, sh.MAGENTA, sh.BLACK, '2');
    sh.drawSprite(6, 10, sh.MUSTARD, sh.BLACK, '3');
    sh.drawSprite(7, 10, sh.DARK_BLUE, sh.BLACK, '4');
    sh.drawSprite(8, 10, sh.PASTEL_RED, sh.BLACK, '5');
    sh.drawSprite(9, 10, sh.PASTEL_PINK, sh.BLACK, '6');
    sh.drawSprite(10, 10, sh.PASTEL_BLUE, sh.BLACK, '7');
    sh.drawSprite(11, 10, sh.PASTEL_ORANGE, sh.BLACK, '8');
    // letters test

    sh.drawSprite(4, 11, sh.TEAL, sh.BLACK, 'a');
    sh.drawSprite(5, 11, sh.MAGENTA, sh.BLACK, 'b');
    sh.drawSprite(6, 11, sh.MUSTARD, sh.BLACK, 'c');
    sh.drawSprite(7, 11, sh.DARK_BLUE, sh.BLACK, 'd');
    sh.drawSprite(8, 11, sh.PASTEL_RED, sh.BLACK, 'e');
    sh.drawSprite(9, 11, sh.PASTEL_PINK, sh.BLACK, 'f');
    sh.drawSprite(10, 11, sh.PASTEL_BLUE, sh.BLACK, 'g');
    sh.drawSprite(11, 11, sh.PASTEL_ORANGE, sh.BLACK, 'h');
    sh.drawSprite(12, 11, sh.PASTEL_ORANGE, sh.BLACK, 2);
    sh.drawSprite(
        state.player.x,
        state.player.y,
        state.player.fg,
        state.player.bg,
        state.player.char,
    );
}

pub fn input(event: c.SDL_Event, quit: *bool) void {
    const key = event.key.keysym.sym;
    switch (event.type) {
        c.SDL_QUIT => {
            quit.* = true;
        },
        c.SDL_KEYDOWN => {
            if (key == c.SDLK_ESCAPE) {
                quit.* = true;
            }
            if (key == c.SDLK_a) {
                state.player.x -= 1;
            }
            if (key == c.SDLK_d) {
                state.player.x += 1;
            }
            if (key == c.SDLK_w) {
                state.player.y -= 1;
            }
            if (key == c.SDLK_s) {
                state.player.y += 1;
            }
        },
        else => {},
    }
}

pub fn main() !void {
    try run(.{
        .title = "zRogue",
        .init = init,
        .tick = tick,
        .events = input,
    });
}
