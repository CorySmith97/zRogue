/// LIBRARY RENDERER

// Imports
const std = @import("std");
const c = @cImport(@cInclude("SDL2/sdl.h"));

const Color = struct {
    r: u8,
    g: u8,
    b: u8,
};

//functions
pub fn draw(ctx: *c.SDL_Renderer, posX: i32, posY: i32, bg: Color, fg: Color, char: u8) void {
    c.SDL_SetRenderDrawColor(
        ctx,
        bg.r,
        bg.g,
        bg.b,
        255,
    );
    _ = posY;
    _ = posX;
    _ = fg;
    _ = char;
}
