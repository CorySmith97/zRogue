const std = @import("std");
const c = @import("c.zig");

const Self = @This();

title: [*c]const u8,
width: i32,
height: i32,
window: ?*c.SDL_Window = undefined,
context: c.SDL_GLContext = undefined,

pub fn init(title: [*c]const u8, width: i32, height: i32) Self {
    return .{
        .title = title,
        .width = width,
        .height = height,
    };
}

// Makes a new window with OpenGL 3.3
pub fn createWindow(self: *Self) void {
    if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
        std.debug.print("ERROR in intialization: {s}\n", .{c.SDL_GetError()});
        return;
    }
    _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_MAJOR_VERSION, 3);
    _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_MINOR_VERSION, 3);
    _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_PROFILE_MASK, c.SDL_GL_CONTEXT_PROFILE_CORE);
    self.window = c.SDL_CreateWindow(
        @ptrCast(self.title),
        100,
        100,
        self.width,
        self.height,
        c.SDL_WINDOW_OPENGL | c.SDL_WINDOW_SHOWN,
    );
}

pub fn deinit(self: *Self) void {
    c.SDL_DestroyWindow(self.window);
    c.SDL_GL_DeleteContext(self.context);
}

pub fn getGLContext(self: *Self) !void {
    self.context = c.SDL_GL_CreateContext(self.window);
    if (self.context == null) {
        return error.GLContextCreationFailed;
    }
}

pub fn swapWindow(self: *Self) void {
    c.SDL_GL_SwapWindow(self.window);
}

pub fn drawBackgroundColor(self: *Self, r: f32, g: f32, b: f32) void {
    _ = self;
    c.glClearColor(r, g, b, 1.0);
    c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT);
}

test "window" {
    const window = Self.init("test", 800, 600);
    std.testing.expect(window.window == null);
}
