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
// Imports
const std = @import("std");
const log = std.log;

/// Struct for initializing a new app. This
/// is passed into the run function which then
/// takes over and runs the basic game. This can also be viewed
/// as our configuation layer between the user and the library
pub const AppDesc = struct {
    const Self = @This();
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

const ver = struct {
    pos: [3]f32,
    norm: [3]f32,
    tex: [2]f32,

    pub fn toArray(self: *ver) []f32 {
        var array = self.pos ++ self.norm ++ self.tex;
        return &array;
    }
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
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    rng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });

    const embedded_bmp = @embedFile("assets/vga8x16.bmp");

    const bm = try BMP.create(embedded_bmp);
    //try bm.flipVertically(allocator);

    var img = Image.initFromBmp(bm);
    var window = Window.init(app.title, 1200, 800);
    window.createWindow();
    defer window.deinit();

    try window.getGLContext();

    const embedded_vs = @embedFile("assets/vert.vs");
    const embedded_fs = @embedFile("assets/frag.fs");
    const mesh_vs = @embedFile("assets/mesh.vs");
    const mesh_fs = @embedFile("assets/mesh.fs");

    var vertices = std.ArrayList(f32).init(allocator);

    const vert = [_]f32{
        -1,
        1,
        1,
        -0.57732844,
        0.57736117,
        0.57736117,
        0.875,
        0.5,
        1,
        -1,
        1,
        0.57732844,
        -0.57736117,
        0.57736117,
        0.625,
        0.75,
        1,
        1,
        1,
        0.5773721,
        0.57733935,
        0.57733935,
        0.625,
        0.5,
        -1,
        -1,
        -1,
        -0.57732844,
        -0.57736117,
        -0.57736117,
        0.375,
        1,
        1,
        -1,
        -1,
        0.5773721,
        -0.57733935,
        -0.57733935,
        0.375,
        0.75,
        -1,
        -1,
        1,
        -0.5773721,
        -0.57733935,
        0.57733935,
        0.625,
        0,
        -1,
        1,
        -1,
        -0.5773721,
        0.57733935,
        -0.57733935,
        0.375,
        0.25,
        -1,
        -1,
        -1,
        -0.57732844,
        -0.57736117,
        -0.57736117,
        0.375,
        0,
        1,
        1,
        -1,
        0.57732844,
        0.57736117,
        -0.57736117,
        0.375,
        0.5,
        -1,
        -1,
        -1,
        -0.57732844,
        -0.57736117,
        -0.57736117,
        0.125,
        0.75,
        -1,
        1,
        -1,
        -0.5773721,
        0.57733935,
        -0.57733935,
        0.125,
        0.5,
        -1,
        1,
        1,
        -0.57732844,
        0.57736117,
        0.57736117,
        0.625,
        0.25,
        -1,
        -1,
        1,
        -0.5773721,
        -0.57733935,
        0.57733935,
        0.875,
        0.75,
        -1,
        -1,
        1,
        -0.5773721,
        -0.57733935,
        0.57733935,
        0.625,
        1,
    };
    try vertices.appendSlice(&vert);
    const inds = [_]u16{
        0,  1,  2,
        1,  3,  4,
        5,  6,  7,
        8,  9,  10,
        2,  4,  8,
        11, 8,  6,
        0,  12, 1,
        1,  13, 3,
        5,  11, 6,
        8,  4,  9,
        2,  1,  4,
        11, 2,  8,
    };
    //
    const texture = try img.imgToTexture();
    var indices = std.ArrayList(u16).init(allocator);
    var textures = std.ArrayList(Mesh.Texture).init(allocator);
    try textures.append(.{ .id = texture, .name = "sheet" });

    try indices.appendSlice(&inds);

    var m: Mesh = undefined;
    try m.init(vertices, indices, textures);
    std.log.info("{any}", .{m});
    var v = ver{
        .pos = .{ 1, 1, 1 },
        .norm = .{ 2, 2, 2 },
        .tex = .{ 1, 1 },
    };
    std.log.info("Array: {any}", .{v.toArray()});
    var camera: Camera = undefined;
    camera.init(@as(f32, @floatFromInt(1200 / 800)));
    var shd = try Shader.init(embedded_vs, embedded_fs);
    _ = &shd; // autofix
    var shd2 = try Shader.init(mesh_vs, mesh_fs);
    const model_matrix: Camera.mat4 = .{
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1,
    };
    //img.free();

    if (app.init) |init| {
        try init();
    }
    log.info("[LOG] LibEpoxy Version: {}\n", .{c.epoxy_gl_version()});
    var a: u32 = 0;
    var b: u32 = 0;
    var delta: f64 = 0;

    var angle: f32 = 0;

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
                try events(&ev);
            }
            if (ev.ev.type == c.SDL_QUIT) {
                quit = true;
            }
        }
        var x: i32 = undefined;
        var y: i32 = undefined;
        const mouse = c.SDL_GetMouseState(&x, &y);
        std.log.info("MOUSE: {any}", .{mouse});
        std.log.info("MOUSE x: {}", .{x});
        std.log.info("MOUSE y: {}", .{y});
        camera.recalcViewProj();
        //shd.setMat4("model", model_matrix);
        //shd.setMat4("view", camera.view_matrix);
        //shd.setMat4("projection", camera.projection_matrix);
        shd2.setMat4("model", model_matrix);
        shd2.setMat4("view", camera.view_matrix);
        shd2.setMat4("projection", camera.projection_matrix);
        //camera.position[0] += 1;
        //camera.view_matrix = Camera.lookAt(camera.position, camera.target, camera.up);
        if (angle >= 360) {
            angle = 0;
        }
        camera.rotation = 0;
        angle += 0.0005;

        c.glEnable(c.GL_DEPTH_TEST);
        window.drawBackgroundColor(0.0, 0.3, 0.3);
        c.glUseProgram(shd2.id);
        m.draw();
        //c.glUseProgram(shd.id);
        //c.glActiveTexture(c.GL_TEXTURE0);
        //c.glBindTexture(c.GL_TEXTURE_2D, texture);

        const keystate = c.SDL_GetKeyboardState(null);

        if (keystate[c.SDL_SCANCODE_UP] == 1) {
            const radius = Camera.distanceBetweenVec3(camera.position, camera.target);
            //std.log.info("TARGET: {any}", .{camera.target});
            if (radius > 1.0) {
                camera.position = Camera.addVec3(
                    camera.position,
                    Camera.scaleVec3(camera.front(), 0.016),
                );
            }
        }
        if (keystate[c.SDL_SCANCODE_DOWN] == 1) {
            const radius = Camera.distanceBetweenVec3(camera.position, camera.target);
            //std.log.info("TARGET: {any}", .{camera.target});
            if (radius < 10.0) {
                camera.position = Camera.subVec3(
                    camera.position,
                    Camera.scaleVec3(camera.front(), 0.016),
                );
            }
        }
        if (keystate[c.SDL_SCANCODE_L] == 1) {
            camera.position = Camera.subVec3(camera.position, Camera.scaleVec3(
                Camera.normalizeVec3(Camera.crossVec3(camera.front(), camera.up)),
                0.016,
            ));
            camera.target = Camera.subVec3(camera.target, Camera.scaleVec3(
                Camera.normalizeVec3(Camera.crossVec3(camera.front(), camera.up)),
                0.016,
            ));
        }
        if (keystate[c.SDL_SCANCODE_H] == 1) {
            camera.position = Camera.addVec3(camera.position, Camera.scaleVec3(
                Camera.normalizeVec3(Camera.crossVec3(camera.front(), camera.up)),
                0.016,
            ));
            camera.target = Camera.addVec3(camera.target, Camera.scaleVec3(
                Camera.normalizeVec3(Camera.crossVec3(camera.front(), camera.up)),
                0.016,
            ));
        }
        if (keystate[c.SDL_SCANCODE_LEFT] == 1) {
            camera.position = Camera.subVec3(camera.position, Camera.scaleVec3(
                Camera.normalizeVec3(Camera.crossVec3(camera.front(), camera.up)),
                0.016,
            ));
        }
        if (keystate[c.SDL_SCANCODE_RIGHT] == 1) {
            camera.position = Camera.addVec3(camera.position, Camera.scaleVec3(
                Camera.normalizeVec3(Camera.crossVec3(camera.front(), camera.up)),
                0.016,
            ));
        }

        if (app.tick) |tick| {
            try tick();
        }
        window.swapWindow();
        b = a;
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
pub const KEY_Right = c.SDLK_RIGHT;
pub const KEY_Left = c.SDLK_LEFT;
pub const KEY_Up = c.SDLK_UP;
pub const KEY_Down = c.SDLK_DOWN;
pub const KEY_Tab = c.SDLK_TAB;
pub const KEY_Enter = c.SDLK_RETURN;
pub const KEY_Backspace = c.SDLK_BACKSPACE;
pub const KEY_Space = c.SDLK_SPACE;
pub const KEY_1 = c.SDLK_1;
pub const KEY_2 = c.SDLK_2;
pub const KEY_3 = c.SDLK_3;
pub const KEY_4 = c.SDLK_4;
pub const KEY_5 = c.SDLK_5;
pub const KEY_6 = c.SDLK_6;
pub const KEY_7 = c.SDLK_7;
pub const KEY_8 = c.SDLK_8;
pub const KEY_9 = c.SDLK_9;
pub const KEY_0 = c.SDLK_0;
