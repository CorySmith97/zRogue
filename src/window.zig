const std = @import("std");
const c = @cImport({
    @cInclude("stb_image.h");
    @cInclude("SDL2/sdl.h");
    @cInclude("epoxy/gl.h");
});

const Self = @This();

title: []const u8,
width: i32,
height: i32,
window: ?*c.SDL_Window = undefined,
context: c.SDL_GLContext = undefined,

pub fn init(title: []const u8, width: i32, height: i32) Self {
    return .{
        .title = title,
        .width = width,
        .height = height,
    };
}

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
