/// LIBRARY RENDERER

// Imports
const std = @import("std");
const c = @cImport(@cInclude("SDL2/sdl.h"));

const Self = @This();
renderer: c.SDL_Renderer,

const Color = struct {
    r: u8,
    g: u8,
    b: u8,
};
//functions
pub fn draw(self: *Self, posX: i32, posY: i32, bg: Color, fg: Color, char: u8) void {
    _ = self;
    _ = posY;
    _ = posX;
    _ = bg;
    _ = fg;
    _ = char;
}
