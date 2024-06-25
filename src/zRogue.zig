///
/// ███████╗██████╗  ██████╗  ██████╗ ██╗   ██╗███████╗
/// ╚══███╔╝██╔══██╗██╔═══██╗██╔════╝ ██║   ██║██╔════╝
///   ███╔╝ ██████╔╝██║   ██║██║  ███╗██║   ██║█████╗
///  ███╔╝  ██╔══██╗██║   ██║██║   ██║██║   ██║██╔══╝
/// ███████╗██║  ██║╚██████╔╝╚██████╔╝╚██████╔╝███████╗
/// ╚══════╝╚═╝  ╚═╝ ╚═════╝  ╚═════╝  ╚═════╝ ╚══════╝

// seperation

/// These are the interfaces for the main library.
pub const Image = @import("image.zig");
pub const Shader = @import("Shader.zig");
pub const Window = @import("window.zig");
pub const Sprite = @import("spritesheet.zig");
// Imports
const std = @import("std");
const log = std.log;
const c = @import("c.zig");

/// Struct for initializing a new app. This
/// is passed into the run function which then
/// takes over and runs the basic game.
pub const AppDesc = struct {
    const Self = @This();
    title: [*c]const u8,
    //allocator: std.heap.ArenaAllocator,
    width: i32 = 80,
    height: i32 = 50,
    tile_width: i32 = 12,
    tile_height: i32 = 12,
    target_fps: i32 = 60,

    /// user defined functions
    init: ?*const fn () void = null,
    tick: ?*const fn () void = null,
    events: ?*const fn (event: *Event) void = null,
};

/// This funciton is our app's entry point. We use struct intialization
/// in order to help keep this clean.
pub fn run(app: AppDesc) !void {
    var img = try Image.init("src/assets/vga8x16.jpg");
    var window = Window.init(app.title, 800, 600);
    window.createWindow();
    defer window.deinit();

    try window.getGLContext();

    const shd = try Shader.init("src/test.vs", "src/test.fs");
    const texture = try img.imgToTexture();
    img.free();

    if (app.init) |init| {
        init();
    }
    log.info("[LOG] LibEpoxy Version: {}\n", .{c.epoxy_gl_version()});
    var a: u32 = 0;
    var b: u32 = 0;
    var delta: f64 = 0;

    var quit = false;
    while (!quit) {
        a = c.SDL_GetTicks();
        delta = @as(f64, @floatFromInt(a - b));
        var event: c.SDL_Event = undefined;
        var ev: Event = .{
            .ev = &event,
            .key = &event.key.keysym.sym,
            .quit = &quit,
        };
        while (c.SDL_PollEvent(ev.ev) != 0) {
            if (app.events) |events| {
                events(&ev);
            }
            if (ev.ev.type == c.SDL_QUIT) {
                quit = true;
            }
        }

        window.drawBackgroundColor(0.0, 0.0, 0.0);
        c.glUseProgram(shd.id);
        c.glActiveTexture(c.GL_TEXTURE0);
        c.glBindTexture(c.GL_TEXTURE_2D, texture);

        if (app.tick) |tick| {
            tick();
        }

        //c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
        window.swapWindow();
        b = a;
    }
}

pub const Event = struct {
    const Self = @This();
    ev: *c.SDL_Event,
    key: *i32,
    quit: *bool,

    pub fn isKeyDown(self: *Self, key: c_int) bool {
        if (self.ev.type == c.SDL_KEYDOWN) {
            return (self.key.* == key);
        }
        return false;
    }
    pub fn windowShouldClose(self: *Self, shouldClose: bool) void {
        self.quit.* = shouldClose;
    }
};

const KEYTYPE = c.SDL_Event.key.keysym.sym;
pub const KEY_A = c.SDLK_a;
pub const KEY_B = c.SDLK_b;
pub const KEY_C = c.SDLK_c;
pub const KEY_D = c.SDLK_d;
pub const KEY_E = c.SDLK_e;
pub const KEY_F = c.SDLK_f;
pub const KEY_G = c.SDLK_g;
pub const KEY_H = c.SDLK_h;
pub const KEY_I = c.SDLK_i;
pub const KEY_J = c.SDLK_j;
pub const KEY_K = c.SDLK_k;
pub const KEY_L = c.SDLK_l;
pub const KEY_M = c.SDLK_m;
pub const KEY_N = c.SDLK_n;
pub const KEY_O = c.SDLK_o;
pub const KEY_P = c.SDLK_p;
pub const KEY_Q = c.SDLK_q;
pub const KEY_R = c.SDLK_r;
pub const KEY_S = c.SDLK_s;
pub const KEY_T = c.SDLK_t;
pub const KEY_U = c.SDLK_u;
pub const KEY_V = c.SDLK_v;
pub const KEY_W = c.SDLK_w;
pub const KEY_X = c.SDLK_x;
pub const KEY_Y = c.SDLK_y;
pub const KEY_Z = c.SDLK_z;
pub const KEY_Escape = c.SDLK_ESCAPE;
