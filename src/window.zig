const std = @import("std");
const c = @import("c.zig");

const Self = @This();

title: [*c]const u8,
width: i32,
height: i32,
window: ?*c.SDL_Window = undefined,
context: c.SDL_GLContext = undefined,

/// Creates a Window object that is /wrapper for SDL2
pub fn init(title: [*c]const u8, width: i32, height: i32) Self {
    return .{
        .title = title,
        .width = width,
        .height = height,
    };
}

/// Makes a new window with OpenGL 3.3
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

/// Destroys our window as well as the Opengl Context
pub fn deinit(self: *Self) void {
    c.SDL_DestroyWindow(self.window);
    c.SDL_GL_DeleteContext(self.context);
}

/// Creates a new Opengl context. On failure throws an error
pub fn getGLContext(self: *Self) !void {
    self.context = c.SDL_GL_CreateContext(self.window);
    if (self.context == null) {
        return error.GLContextCreationFailed;
    }
}

/// Swaps the window buffer for rendering
pub fn swapWindow(self: *Self) void {
    c.SDL_GL_SwapWindow(self.window);
}

/// Draw a background of provided color. Color values are between 0 and 1
pub fn drawBackgroundColor(self: *Self, r: f32, g: f32, b: f32) void {
    _ = self;
    c.glClearColor(r, g, b, 1.0);
    c.glClear(c.GL_COLOR_BUFFER_BIT);
}
