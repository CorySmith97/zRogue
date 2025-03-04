///
/// ███████╗██████╗  ██████╗  ██████╗ ██╗   ██╗███████╗
/// ╚══███╔╝██╔══██╗██╔═══██╗██╔════╝ ██║   ██║██╔════╝
///   ███╔╝ ██████╔╝██║   ██║██║  ███╗██║   ██║█████╗
///  ███╔╝  ██╔══██╗██║   ██║██║   ██║██║   ██║██╔══╝
/// ███████╗██║  ██║╚██████╔╝╚██████╔╝╚██████╔╝███████╗
/// ╚══════╝╚═╝  ╚═╝ ╚═════╝  ╚═════╝  ╚═════╝ ╚══════╝

//

/// These are the interfaces for the main library.
pub const App = @import("app.zig");
const Image = App.Image;
const Shader = App.Shader;
const Window = App.Window;
const Sprite = App.Sprite;
const BMP = App.Bmp;
const c = App.c;
pub const Algorithms = @import("algorithms.zig");
pub const Geometry = @import("math/geometry.zig");
pub const Network = @import("network/network.zig");
const Camera = App.Camera;
const Mesh = App.Mesh;
const vec3 = App.Camera.vec3;
const vec2 = App.Camera.vec2;
pub const Texture = c.GLuint;
// Imports
const std = @import("std");
const log = std.log;

const SpriteSheetInfo = struct {
    spritesheet_name: []const u8,
    sprite_height: i32,
    sprite_width: i32,
};

const RootState = struct {
    allocator: std.mem.Allocator,
    sprite_contants: Sprite.SpriteConstants,
    selected_spritesheet: u32,
    spritesheets: std.StringHashMap(Texture),
    projection: Camera.mat4,

    fn initRootState(self: *RootState, spritesheet_info: []const SpriteSheetInfo) !void {
        const allocator = std.heap.page_allocator;
        self.* = .{
            .allocator = allocator,
            .sprite_contants = .{},
            .spritesheets = std.StringHashMap(Texture).init(allocator),
            .selected_spritesheet = 0,
            .projection = Camera.ortho(
                0,
                1200,
                800,
                0,
                0.1,
                1.0,
            ),
        };

        var dir = try std.fs.cwd().openDir("src/assets", .{ .iterate = true });
        for (spritesheet_info) |ssi| {
            var texture_array: Texture = undefined;
            c.glGenTextures(1, &texture_array);
            c.glBindTexture(c.GL_TEXTURE_2D_ARRAY, texture_array);
            const bind_err = c.glGetError();
            if (bind_err != c.GL_NO_ERROR) {
                std.log.err("Texture binding error: {}", .{bind_err});
            }
            var f = try dir.openFile(ssi.spritesheet_name, .{});
            defer f.close();
            const embedded_file = try f.readToEndAlloc(allocator, 10_000_000_000);
            defer allocator.free(embedded_file);
            const bm = try BMP.create(embedded_file);
            const layers = (@divTrunc(@as(i32, @intCast(bm.width)), ssi.sprite_width)) * (@divTrunc(@as(i32, @intCast(bm.height)), ssi.sprite_height)) + 1;
            c.glPixelStorei(c.GL_UNPACK_ALIGNMENT, 1);
            c.glTexParameteri(c.GL_TEXTURE_2D_ARRAY, c.GL_TEXTURE_MIN_FILTER, c.GL_LINEAR);
            c.glTexParameteri(c.GL_TEXTURE_2D_ARRAY, c.GL_TEXTURE_MAG_FILTER, c.GL_LINEAR);
            c.glTexParameteri(c.GL_TEXTURE_2D_ARRAY, c.GL_TEXTURE_WRAP_S, c.GL_CLAMP_TO_EDGE);
            c.glTexParameteri(c.GL_TEXTURE_2D_ARRAY, c.GL_TEXTURE_WRAP_T, c.GL_CLAMP_TO_EDGE);
            c.glTexParameteri(c.GL_TEXTURE_2D_ARRAY, c.GL_TEXTURE_BASE_LEVEL, 0);
            c.glTexParameteri(c.GL_TEXTURE_2D_ARRAY, c.GL_TEXTURE_MAX_LEVEL, 0);
            c.glTexImage3D(c.GL_TEXTURE_2D_ARRAY, 0, c.GL_RGB, @intCast(ssi.sprite_width), @intCast(ssi.sprite_height), @intCast(layers), 0, c.GL_RGB, c.GL_UNSIGNED_BYTE, null);

            var sprite_count: i32 = 0;
            var row: usize = 0;
            var col: usize = 0;
            while (row < bm.height) : (row += @intCast(ssi.sprite_height)) {
                col = 0;
                while (col < bm.width) : (col += @intCast(ssi.sprite_width)) {
                    const region = try extractRegion(allocator, bm.raw, ssi.sprite_width, ssi.sprite_height, @intCast(col), @intCast(row), bm.width, 3);
                    if (!isAllZeros(region)) {
                        c.glTexSubImage3D(
                            c.GL_TEXTURE_2D_ARRAY,
                            0,
                            0,
                            0,
                            @intCast(sprite_count),
                            @intCast(ssi.sprite_width),
                            @intCast(ssi.sprite_height),
                            1,
                            c.GL_RGB,
                            c.GL_UNSIGNED_BYTE,
                            region.ptr,
                        );
                        sprite_count += 1;
                    }
                }
            }
            std.log.info("layers: {}, Sprite count: {}", .{ layers, sprite_count });
            std.log.info("height: {}, width: {}", .{ bm.height, bm.width });
            try self.spritesheets.put(ssi.spritesheet_name, texture_array);
        }
    }
};

fn isAllZeros(data: []const u8) bool {
    for (data) |byte| {
        if (byte != 0) {
            return false;
        }
    }
    return true;
}

fn extractRegion(allocator: std.mem.Allocator, data: []const u8, sprite_width: i32, sprite_height: i32, x: i32, y: i32, atlas_width: u32, bytes_per_pixel: i32) ![]const u8 {
    const row_size = sprite_width * bytes_per_pixel;
    const rs: usize = @intCast(row_size);

    const sub_size: usize = @intCast(sprite_width * sprite_height * bytes_per_pixel);
    var region = try allocator.alloc(u8, sub_size);

    const aw: i32 = @intCast(atlas_width);
    for (0..@intCast(sprite_height)) |r| {
        const row: i32 = @intCast(r);
        const src_index: usize = @intCast(((y + row) * aw + x) * bytes_per_pixel);
        const dst_index: usize = @intCast(row * row_size);
        @memcpy(region[dst_index .. dst_index + rs], data[src_index .. src_index + rs]);
    }

    return region;
}
pub var rootstate: RootState = undefined;

/// Struct for initializing a new app. This
/// is passed into the run function which then
/// takes over and runs the basic game. This can also be viewed
/// as our configuation layer between the user and the library
pub const AppDesc = struct {
    const Self = @This();
    screen_width: i32 = 1200,
    screen_height: i32 = 800,
    h_tile_count: f32 = 80,
    v_tile_count: f32 = 50,
    show_fps: bool = false,
    title: [*c]const u8,
    /// user defined functions
    /// Init happens before any main loop
    init: ?*const fn () anyerror!void = null,
    /// tick happens once per loop. This is meant for logic and rendering
    tick: ?*const fn () anyerror!void = null,
    /// events happens onces per loop. Additionally this is mean to handle input
    events: ?*const fn (event: *Event) anyerror!void = null,
    cleanup: ?*const fn () anyerror!void = null,
};

pub var rng: std.Random.Xoshiro256 = undefined;

/// This funciton is our app's entry point. We use struct intializatiteston
/// in order to help keep this clean. The App desc is a struct with a handful
/// of parameters a user can define. The order of user functions called in
/// run are as follows:
/// init()
/// while (!windowShouldClose) {
///     events()
///     tick()
/// }
/// cleanup()
pub fn run(app: AppDesc) !void {
    //var buf: [100]u8 = undefined;
    rng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });

    var window = Window.init(app.title, app.screen_width, app.screen_height);
    window.createWindow();
    defer window.deinit();

    try window.getGLContext();

    const embedded_vs = @embedFile("assets/vert.vs");
    const embedded_fs = @embedFile("assets/frag.fs");

    try rootstate.initRootState(&[_]SpriteSheetInfo{
        .{ .sprite_width = 8, .sprite_height = 16, .spritesheet_name = "vga8x16.bmp" },
    });
    var shd = try Shader.init(embedded_vs, embedded_fs);
    c.glUseProgram(shd.id);
    Sprite.makeVao(&shd);
    shd.setInt("atlas", @intCast(rootstate.spritesheets.get("vga8x16.bmp").?));

    Sprite.sprite_constants = .{
        .v_tile_size = app.v_tile_count,
        .h_tile_size = app.h_tile_count,
        .screen_width = app.screen_width,
        .screen_height = app.screen_height,
    };

    const err = c.glGetError();
    if (err != c.GL_NO_ERROR) {
        std.log.err("OpenGL error: {}", .{err});
    }

    //img.free();

    if (app.init) |init| {
        try init();
    }
    log.info("[LOG] LibEpoxy Version: {}\n", .{c.epoxy_gl_version()});
    var a: u32 = 0;

    var quit = false;
    while (!quit) {
        //var timer = try std.time.Timer.start();
        a = c.SDL_GetTicks();
        var event: c.SDL_Event = undefined;
        var ev: Event = .{
            .ev = &event,
            .key = &event.key.keysym.sym,
            .quit = &quit,
        };
        while (c.SDL_PollEvent(ev.ev) != 0) {
            if (app.events) |events| {
                try events(&ev);
            }
            if (ev.ev.type == c.SDL_QUIT) {
                quit = true;
            }
            c.SDL_FlushEvents(c.SDL_KEYDOWN, c.SDL_KEYUP);
        }

        window.drawBackgroundColor(0.0, 0.0, 0.0);

        const er = c.glGetError();
        if (er != c.GL_NO_ERROR) {
            std.log.err("OpenGL error: {}", .{er});
        }

        c.glBindTexture(c.GL_TEXTURE_2D_ARRAY, rootstate.spritesheets.get("vga8x16.bmp").?);
        if (app.tick) |tick| {
            try tick();
        }
        const sdl_delta = c.SDL_GetTicks() - a;
        if (sdl_delta < 16) {
            c.SDL_Delay(16 - sdl_delta);
        }
        //const frame_delta = timer.read();
        //if (app.show_fps) {
        //    const fs = @as(f32, @floatFromInt(1_000_000_000 / frame_delta));
        //    const fps = try std.fmt.bufPrint(&buf, "FPS: {d:.2}", .{fs});
        //    Sprite.print(0, 1, Sprite.WHITE, Sprite.BLACK, fps);
        //}
        window.swapWindow();
    }
    if (app.cleanup) |cleanup| {
        try cleanup();
    }
}

/// Events are the way to get information from user.
/// There are only a finite number of functions now to
/// interact. More will be added with time.
pub const Event = struct {
    const Self = @This();
    ev: *c.SDL_Event,
    key: *i32,
    quit: *bool,

    // Checks if a provided key is pressed down. Returns true or false
    pub fn isKeyDown(self: *Self, key: c_int) bool {
        if (self.ev.type == c.SDL_KEYDOWN) {
            return (self.key.* == key);
        }
        return false;
    }
    // User definition for closing the window outside of pressing the X
    // at the top of the window ie. Key to close the window or game
    // condition.
    pub fn windowShouldClose(self: *Self, shouldClose: bool) void {
        self.quit.* = shouldClose;
    }
};

pub const Vec2 = struct {
    x: f32,
    y: f32,
};

pub fn getMousePos() Vec2 {
    var x: c_int = 0;
    var y: c_int = 0;
    _ = c.SDL_GetMouseState(&x, &y);

    return .{ .x = @floatFromInt(x), .y = @floatFromInt(y) };
}

const KEYTYPE = c.SDL_Event.key.keysym.sym;
pub const Keys = struct {
    pub const KEY_A: c_int = c.SDLK_a;
    pub const KEY_B: c_int = c.SDLK_b;
    pub const KEY_C: c_int = c.SDLK_c;
    pub const KEY_D: c_int = c.SDLK_d;
    pub const KEY_E: c_int = c.SDLK_e;
    pub const KEY_F: c_int = c.SDLK_f;
    pub const KEY_G: c_int = c.SDLK_g;
    pub const KEY_H: c_int = c.SDLK_h;
    pub const KEY_I: c_int = c.SDLK_i;
    pub const KEY_J: c_int = c.SDLK_j;
    pub const KEY_K: c_int = c.SDLK_k;
    pub const KEY_L: c_int = c.SDLK_l;
    pub const KEY_M: c_int = c.SDLK_m;
    pub const KEY_N: c_int = c.SDLK_n;
    pub const KEY_O: c_int = c.SDLK_o;
    pub const KEY_P: c_int = c.SDLK_p;
    pub const KEY_Q: c_int = c.SDLK_q;
    pub const KEY_R: c_int = c.SDLK_r;
    pub const KEY_S: c_int = c.SDLK_s;
    pub const KEY_T: c_int = c.SDLK_t;
    pub const KEY_U: c_int = c.SDLK_u;
    pub const KEY_V: c_int = c.SDLK_v;
    pub const KEY_W: c_int = c.SDLK_w;
    pub const KEY_X: c_int = c.SDLK_x;
    pub const KEY_Y: c_int = c.SDLK_y;
    pub const KEY_Z: c_int = c.SDLK_z;
    pub const KEY_Escape: c_int = c.SDLK_ESCAPE;
    pub const KEY_Right: c_int = c.SDLK_RIGHT;
    pub const KEY_Left: c_int = c.SDLK_LEFT;
    pub const KEY_Up: c_int = c.SDLK_UP;
    pub const KEY_Down: c_int = c.SDLK_DOWN;
    pub const KEY_Tab: c_int = c.SDLK_TAB;
    pub const KEY_Enter: c_int = c.SDLK_RETURN;
    pub const KEY_Backspace: c_int = c.SDLK_BACKSPACE;
    pub const KEY_Space: c_int = c.SDLK_SPACE;
    pub const KEY_1: c_int = c.SDLK_1;
    pub const KEY_2: c_int = c.SDLK_2;
    pub const KEY_3: c_int = c.SDLK_3;
    pub const KEY_4: c_int = c.SDLK_4;
    pub const KEY_5: c_int = c.SDLK_5;
    pub const KEY_6: c_int = c.SDLK_6;
    pub const KEY_7: c_int = c.SDLK_7;
    pub const KEY_8: c_int = c.SDLK_8;
    pub const KEY_9: c_int = c.SDLK_9;
    pub const KEY_0: c_int = c.SDLK_0;
};
