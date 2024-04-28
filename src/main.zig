const std = @import("std");
const c = @cImport(@cInclude("SDL2/sdl.h"));
const State = @import("lib/app.zig");

const state: State.State = undefined;
fn tick(s: *State.State) void {
    _ = s;
    var quit = false;
    while (!quit) {
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                c.SDL_QUIT => {
                    quit = true;
                },
                else => {},
            }
        }
    }
}
pub fn main() !void {
    State.run(State.State{
        .title = "Rogue",
        .width = 100,
        .height = 100,
        .tick = tick,
    });
}
